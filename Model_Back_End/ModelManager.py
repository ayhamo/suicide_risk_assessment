from io import BytesIO
from threading import Lock
from threading import Semaphore

import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib
matplotlib.use('Agg') #Agg backend for Matplotlib that can only write to files
import matplotlib.pyplot as plt

from sklearn.feature_extraction.text import TfidfVectorizer
from wordcloud import WordCloud

import tensorflow as tf
import transformers
from transformers import TFRobertaModel
from keras_preprocessing.sequence import pad_sequences

from flask import Flask, request, jsonify, send_file, Response
from flask_cors import CORS


app = Flask(__name__)
CORS(app)


if __name__ =="__main__":
    app.run(debug=True)


# Global variables to store models in memory
suicide_model = None
polarity_emotion_model = None

#Global variables to store the dataset
dataset = None

# Global variable to store the result of keyword_extraction
keyword_extraction_result = None

# Global variable to store the word cloud image data
wordcloud_image_data = None

# Global variable to store the occurrence matrix image data
occurrence_matrix_image_data = None

@app.route("/")
def MainPage():
    return "This is Main Page"

# create a model lock, next requests will be handled once the lock unlocks
load_models_lock = Lock()

@app.route('/load_models', methods=['GET'])
def load_models(): 
    global suicide_model, polarity_emotion_model

    # acquire the lock
    #This ensures that only one laod model can execute to prevent multiple loading initially
    with load_models_lock:
        if suicide_model is not None and polarity_emotion_model is not None:
            return jsonify({"message": "Models already loaded"})

        try:
            # Load the first Keras model
            suicide_model = tf.keras.models.load_model('models/Roberta_suicide_label.h5', custom_objects={'TFRobertaModel': TFRobertaModel})

            # Load the second Keras model
            polarity_emotion_model = tf.keras.models.load_model('models/Roberta_polarity_emotion.h5', custom_objects={'TFRobertaModel': TFRobertaModel})

            return jsonify({"message": "Models loaded successfully"})
        except Exception as e:
            return jsonify({"message": f"Server error occurred\nError: {str(e)}"})


# create a semaphore with with only 10 threads (executions) at a time due to high memory useage
predict_semaphore = Semaphore(10)

@app.route('/predict', methods=['POST'])
def predict():
    
    if suicide_model is None and polarity_emotion_model is None:
        response = load_models()
        if 'Server error occurred' in response.json['message']:
            return response
        
    with predict_semaphore:
        # Get the input text from the request body
        text = request.json['text']

        # Prepare the text
        tokenizer = transformers.RobertaTokenizer.from_pretrained('roberta-base')
        text_encoded = tokenizer.encode(text, add_special_tokens=True, truncation=True, max_length=512)
        
        # Pads tokens with a specified value (0 by default) until they are all of the same length
        text_padded = pad_sequences([text_encoded], maxlen=512, dtype="int32", value=0, truncating="post")

        # Make predictions with the first model
        suicide_output = suicide_model.predict(text_padded)
        predicted_index = np.argmax(suicide_output)
        index_to_suicide = {0: 'anxiety', 1: 'suicide watch', 2: 'bipolar', 3: 'depression', 4: 'off my chest'}
        predicted_suicide_name = index_to_suicide[predicted_index]

        # Make predictions with the second model
        polarity_emotion_output = polarity_emotion_model.predict(text_padded)

        # Define the label names for the second model
        label_names = ['pos', 'neg', 'anger', 'fear', 'hopefullness', 'hopelessness', 'joy', 'sadness', 'disgust']

        # Create a dictionary to store the predicted probabilities for each label
        probabilities = {}
        for label_name, probability in zip(label_names, polarity_emotion_output[0]):
            probabilities[label_name] = probability

        # Round the values to two decimal places
        probabilities = {k: round(float(v), 3) for k, v in probabilities.items()}

        # Create a new dictionary for sentiment
        sentiment = {'pos': probabilities['pos'], 'neg': probabilities['neg']}

        # Remove Pos and Neg from probabilities
        del probabilities['pos']
        del probabilities['neg']

        # Return the predictions as a dictionary
        return jsonify({'Suicide_Risk': predicted_suicide_name, 'Sentiment': sentiment, 'Emotions': probabilities})

@app.route('/keywords_graph' , methods=['GET']) # /keywords_graph/<top_n>
def keywords_graph(): #(top_n)
    global keyword_extraction_result
    
    # Check if we have a cached result
    if keyword_extraction_result is None:
        res = keyword_extraction()
        if isinstance(res, Response):
            return res
        keyword_extraction_result = res

    top_n_keywords, top_n_scores = keyword_extraction_result

    # Create a dictionary of words and scores
    result = dict(zip(top_n_keywords, top_n_scores))

    return jsonify(result)

@app.route('/keywords_wordcloud', methods=['GET'])
def keywords_wordcloud():
    global keyword_extraction_result
    global wordcloud_image_data

    # Check if we have a cached result
    if keyword_extraction_result is None:
        res = keyword_extraction()
        if isinstance(res, Response):
            return res
        keyword_extraction_result = res

    top_n_keywords, _ = keyword_extraction_result

    # Check if we have a cached word cloud image
    if wordcloud_image_data is None:
        # Generate the text for the word cloud
        text = ' '.join(top_n_keywords)

        # Create a WordCloud object
        wordcloud = WordCloud(width=3000, height=2000,
                              prefer_horizontal=1.0,
                              background_color='white').generate(text)

        # Plot the word cloud
        plt.imshow(wordcloud)
        plt.axis("off")

        # Plot the word cloud
        fig, ax = plt.subplots()
        ax.imshow(wordcloud)
        ax.axis("off")
        fig.tight_layout(pad=0)

        # Save the figure to an in-memory binary stream
        img_data = BytesIO()
        fig.savefig(img_data, format='png', bbox_inches='tight')
        img_data.seek(0)
        
        # Cache the image data
        wordcloud_image_data = img_data.getvalue()

    # Create a new BytesIO object for the response
    response_img_data = BytesIO(wordcloud_image_data)

    # Return the image data
    return send_file(response_img_data, mimetype='image/png')


@app.route('/occurrence_matrix')
def occurrence_matrix():
    global occurrence_matrix_image_data
    global dataset

    # Check if we have a cached dataset
    if dataset is None:
        res = load_dataset()
        if isinstance(res, Response):
            return res
        dataset = res

    data = dataset

    # Check if we have a cached occurrence matrix image
    if occurrence_matrix_image_data is None:
        # One-hot encode the suicide_label column
        suicide_labels = pd.get_dummies(data['suicide_label'], prefix='suicide_label')

        # Add the one-hot encoded columns to the DataFrame
        data = pd.concat([data, suicide_labels], axis=1)

        # Get the column names for the emotion and suicide labels
        label_cols = ['Pos', 'Neg', 'anger', 'fear', 'hopefullness', 'hopelessness', 'joy', 'sadness', 'calmness', 'disgust'] + list(suicide_labels.columns)

        # Create a co-occurrence matrix
        # counts how many times each pair of labels co-occurs in the dataset.
        n_labels = len(label_cols)
        cooccur_matrix = np.zeros((n_labels, n_labels))
        for i in range(n_labels):
            for j in range(i+1, n_labels):
                count = ((data[label_cols[i]] > 0) & (data[label_cols[j]] > 0)).sum()
                cooccur_matrix[i, j] = count
                cooccur_matrix[j, i] = count

        # Create a DataFrame from the co-occurrence matrix
        cooccur_df = pd.DataFrame(cooccur_matrix, index=label_cols, columns=label_cols)

        # Remove the 'suicide_label_self.' prefix from the row and column labels
        cooccur_df.index = cooccur_df.index.str.replace('suicide_label_self.', '')
        cooccur_df.columns = cooccur_df.columns.str.replace('suicide_label_self.', '')

        # Set the size of the plot
        fig = plt.figure(figsize=(12, 8))

        # Create a heatmap from the DataFrame and set the fmt parameter to display whole numbers
        sns.heatmap(cooccur_df, cmap='Reds', annot=True, fmt='.0f')

        # Save the figure to an in-memory binary stream
        img_data = BytesIO()
        fig.savefig(img_data, format='png', bbox_inches='tight')
        img_data.seek(0)
        
        # Cache the image data
        occurrence_matrix_image_data = img_data.getvalue()

    # Create a new BytesIO object for the response
    response_img_data = BytesIO(occurrence_matrix_image_data)

    # Return the image data
    return send_file(response_img_data, mimetype='image/png')


def load_dataset():
    global dataset
    try:
        # Load your data into a DataFrame
        dataset = pd.read_excel("labled_dataset.xlsx")
    except Exception as e:
        return (jsonify({"message": f"Server error occurred\n{str(e)}"}))
 
    # Get first 5000 and apply pre-processing
    dataset = dataset.head(5000-1)
    dataset['text'] = dataset['text'].apply(remove_chars)

    return dataset


def remove_chars(text):
    # Check if text is NaN(avoid some issues)
    if pd.isna(text):
        return text
    
    # Define the characters you want to keep
    allowed_chars = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?,.![]“„%‚{}’:@-_=()+"` ')

    # Remove all characters that are not in the allowed_chars set
    cleaned_text = ''.join(c for c in text if c in allowed_chars)

    return cleaned_text


def keyword_extraction():
    if dataset is None:
        res = load_dataset()
        if isinstance(res, Response) and 'Server error occurred' in res.json['message']:
            return res
    
    # Create a TfidfVectorizer object with stop_words set to 'english'
    vectorizer = TfidfVectorizer(stop_words='english')

    # Fit the vectorizer to the text data
    X = vectorizer.fit_transform(dataset["text"])

    # Get the feature names (i.e., the words)
    feature_names = vectorizer.get_feature_names_out()

    # Get the TF-IDF scores for each word in each document
    tfidf_scores = X.toarray()

    # Compute the average TF-IDF score for each word
    avg_tfidf_scores = tfidf_scores.mean(axis=0)

    # Get the top n keywords and their scores
    n = 20
    excluded_words = ['im','just', 'dont','deleted','really', 'ive']
    top_n_indices = [i for i in avg_tfidf_scores.argsort()[::-1] if feature_names[i] not in excluded_words][:n]
    top_n_keywords = [feature_names[i] for i in top_n_indices]
    top_n_scores = [avg_tfidf_scores[i] for i in top_n_indices]

    return top_n_keywords, top_n_scores
