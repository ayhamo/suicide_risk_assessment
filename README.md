# Suicide Risk Assessment Program

suicide risk assessment using A.I. to assess given text and give predictions
and represent the predictions in an appropriate charts and formats


*This program was made as a part of my Graduation Thesis project

## Front-End
The Program was made using Flutter for web

To Run:
* Clone the repo
* Run Pub Get, then you can run the application

## Back-End
Flask was used to create the backend of the application, it uses h5 models to load them
and gives prediction

The backend also gives Keywords graph, Word Cloud and correlation matrix

* You can download the models [Here](https://drive.google.com/drive/folders/1XqI4lOd4rUfK11LFvNhlVrb0sF8ndQl5?usp=sharing) 
then put them under Model_Back_End/models where there
  should be one for suicide label and other for polarity and emotions

## Setting Up
* Create new env and get into it using "env\Scripts\activate".
* Run "pip install -r requirements.txt" to install all dependencies.
* use "flask run" command to run the backend
* then you can use the following URLs:
    * /load_models : GET, To load the models initially, it is called automatically on "/predict" also.
    * /predict : POST, requires body header json of {"text" : "..(value).."}
      and content-type of "application/json".
    * /keywords_graph : GET, returns key & value map where each key is the word and value is the
      relevance score.
    * /keywords_wordcloud : GET, returns an image that contains keywords.
    * /occurrence_matrix : GET, returns an image matrix that contains the correlation between labels.

## Online Demo
- TBD