import os
import io

from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename

import numpy as np
import pandas as pd

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import confusion_matrix, r2_score
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA

import xgboost as xgb

import matplotlib
import matplotlib.pyplot as plt
matplotlib.use('Agg')

import joblib
import uuid
import base64

import dbm.dumb as dbm
import json


UPLOAD_FOLDER = './'
ALLOWED_EXTENSIONS = {'txt', 'csv'}
ALLOWED_MODELS = {'classification', 'regression', 'clustering'}

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


@app.route("/healthz")
def health():
     return "OK"


def is_allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def parse_dataset(file, target=None):
    if file and is_allowed_file(file.filename):
        filename = secure_filename(file.filename)
        full_filename = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(full_filename)
        df = pd.read_csv(full_filename, delimiter=',')
        X = df.to_numpy()
        y = None
        if target:
            target = request.args.get("target", default=None)
            if target not in df.columns:
                return None, None
            X = df.drop(target, axis=1).to_numpy()
            y = df[target].to_numpy()
        return X, y
    return None, None



def train_classifier(X, y):
    objective = 'binary:logistic' if len(set(y)) == 2 else 'multi:softprob'
    X_trn, X_tst, y_trn, y_tst = train_test_split(X, y, test_size=0.33, random_state=42)
    clf = Pipeline([('scaler', StandardScaler()),
                    ('clf', xgb.XGBClassifier(objective=objective, random_state=42))])
    clf.fit(X_trn, y_trn)
    y_pred = clf.predict(X_tst)
    clf.fit(X_tst, y_tst)
    conf_mat = confusion_matrix(y_tst, y_pred)
    plot = build_confusion_matrix(conf_mat)
    model_id = str(uuid.uuid4())
    data = {'id': model_id, 'model': clf, 'confusion_matrix': conf_mat, 'plot': plot, 'predictions': y_pred, 'targets': y_tst}
    
    with io.BytesIO() as buff:
        joblib.dump(data, buff)
        buff.seek(0)
        with dbm.open('db_classifier', 'c') as db:
            db[model_id] = buff.read()

    return model_id


def build_confusion_matrix(conf_matrix):
    with io.BytesIO() as buff:
        fig, ax = plt.subplots(figsize=(7.5, 7.5))
        ax.matshow(conf_matrix, cmap=plt.cm.Blues, alpha=0.3)
        for i in range(conf_matrix.shape[0]):
            for j in range(conf_matrix.shape[1]):
                ax.text(x=j, y=i,s=conf_matrix[i, j], va='center', ha='center', size='xx-large')
 
        plt.xlabel('Predictions', fontsize=18)
        plt.ylabel('Targets', fontsize=18)
        plt.title('Confusion Matrix', fontsize=18)
 
        plt.savefig(buff, format='png')
        buff.seek(0)

        return base64.b64encode(buff.getvalue()).decode()


@app.route("/api/v1/classification/train", methods=['POST'])
def train_classifier_csv():
    dataset = []
    if request.files:
        file = request.files['file']
        if file.filename == '':
            return "No file to process", 400
        X, y = parse_dataset(file, request.args.get("target", default=None))
        if y is None:
            return "Target not in dataset", 400
        if X is None:
            return "Wrong payload", 400

        model_id = train_classifier(X, y)
        return model_id, 200
    return "Bad request", 400


@app.route("/api/v1/classification/", methods=['GET'])
def list_classifiers():
    keys = []
    try:
        with dbm.open('db_classifier', 'r') as db:
            keys = [k.decode('utf-8') for k in db.keys()]
    except:
        pass
    return jsonify(keys), 200


@app.route("/api/v1/classification/<model_id>", methods=['GET'])
def get_classifier(model_id):
    try:
        with dbm.open('db_classifier', 'r') as db:
            if model_id in db:
                with io.BytesIO() as buff:
                    buff.write(db[model_id])
                    buff.seek(0)
                    obj = joblib.load(buff)
                    return {'id': obj['id'],
                            'confusion_matrix': obj['confusion_matrix'].tolist(),
                            'targets': obj['targets'].tolist(),
                            'predictions': obj['predictions'].tolist()}, 200
    except:
        return "Not found", 404


@app.route("/api/v1/classification/<model_id>/predict", methods=['POST'])
def predict_classifier_csv(model_id):
    dataset = []
    if request.files:
        file = request.files['file']
        if file.filename == '':
            return "No file to process", 400
        X, y = parse_dataset(file, request.args.get("target", default=None))
        if y is None:
            return "Target not in dataset", 400
        if X is None:
            return "Wrong payload", 400

        result = {'predictions': [], 'confusion_matrix': [], 'plot': ''}
        try:
            with dbm.open('db_classifier', 'r') as db:
                if model_id in db:
                    with io.BytesIO() as buff:
                        buff.write(db[model_id])
                        buff.seek(0)
                        obj = joblib.load(buff)
                        clf = obj['model']
                        preds = clf.predict(X)
                        conf_mat = confusion_matrix(y, preds)
                        plot = build_confusion_matrix(conf_mat)
                        result['predictions'] = preds.tolist()
                        result['confusion_matrix'] = conf_mat.tolist()
                        result['plot'] = plot
        except:
            return "Not found", 404       
                                  
        return jsonify(result), 200
    return "Bad request", 400


if (__name__ == "__main__"):
     app.run(port = 5000)

