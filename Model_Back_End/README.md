# Suicide Risk Assessment Back End

suicide risk using A.I models to assess given text and give predictions

*This program was made as a part of my Graduation Thesis project

## Back-End
Flask was used to create the backend of the application, it uses h5 models to load them
and gives prediction

The backend also gives Keywords graph, Word Cloud and correlation matrix

* You can download the models separately under Model_Back_End/models where there
is one for suicide label and other for polarity and emotions

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