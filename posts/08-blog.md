# Final Election Prediction
## November 1, 2020

(1) model formula (or procedure for obtaining prediction), 
(2) model description and justification, 
(3) coefficients (if using regression) and/or weights (if using ensemble), 
(4) interpretation of coefficients and/or justification of weights, 
(5) model validation (recommended to include both in-sample and out-of-sample performance unless it is impossible due to the characteristics of model and related data availability), 
(6) uncertainty around prediction (e.g. predictive interval)
(7) graphic(s) showing your prediction

"the descriptive evidence suggests coronavirus may influence people's votes, although we can't rule out the alternative"

Just two days ago, FiveThirtyEight's Nate Silver penned the article, ["Trump Can Still Win, But The Polls Would Have To Be Off By Way More Than In 2016"](https://fivethirtyeight.com/features/trump-can-still-win-but-the-polls-would-have-to-be-off-by-way-more-than-in-2016/). My final prediction demonstrates his claim. Only seven states are within five points. Even if Trump won all of them, he would still lose the electoral college. Therefore this election is a battle for the polls. *If Trump wins, my prediction—and predictions of practically the entire industry—will appear even more fraudulent than 2016.* 

<br>

Nevertheless, I still had to set out on this journey. First, I utilized purely weighted polling data to predict state outcomes. Second, I attempted to gain more insight by creating models for the remaining seven toss-up states. Third, I used the models with the best in and out of sample validation to predict their outcomes both with and without the addition of the polling estimates. Fourth, I created probabilistic models for the popular vote and the Electoral College to estimate the uncertainty around my predictions. 

![](../figures/polls_plot.png)

This map displays my poll-based prediction for every state. I did not include fundamentals in my primary prediction for a number of reasons. First, [Nate Silver](https://fivethirtyeight.com/features/how-fivethirtyeights-2020-presidential-forecast-works-and-whats-different-because-of-covid-19/) demonstrates just how volatile of a predictor they can be which was also displayed in [my blog on unemployment](https://samuellowry.github.io/gov1347_blog/posts/02-blog.html)—especially given COVID. Secondly, as noted by [Jennings et al. (2020)](https://www-sciencedirect-com.ezp-prod1.hul.harvard.edu/science/article/pii/S0169207019302572), polls become more predictive the closer to the election they take place which is why at this point in the game [FiveThirtyEight utilizes polls practically exclusively](https://fivethirtyeight.com/features/how-fivethirtyeights-2020-presidential-forecast-works-and-whats-different-because-of-covid-19/).

<br>

Nevertheless, merely aggregating all polls would not be prudent. As [G. Elliot Morris](https://gelliottmorris.com) informed our class, SurveyMonkey and its peers are not to be trusted. Therefore, I weighted polls both by their [FiveThirtyEight grade](https://projects.fivethirtyeight.com/pollster-ratings/) and by their recency. I weighted all the A polls to have three times the influence as the C polls and weighted the B polls to have twice the amount of influence. I completely cut out the D and F polls with the exception of states which don't have recent reliable polls. In those cases, I unfortunately had to rely largely upon SurveyMonkey. Thankfully, I only needed to use such polls in states where no reputable pollster is paid to conduct polls—i.e., states that we all know which way they are gonna go. I also cut out all polls prior to the end of the Democratic Convention—75 from the election. I then weighted polls four weeks out from the election twice as much those between 75 and 28 days out and polls two weeks out from the election three times as much. This left me with seven toss-up states: those where the win margin was within five points. 

![](../figures/final_fit.png)

With the polls being so close within those seven states, even though [I have frowned upon fundamentals](https://www-sciencedirect-com.ezp-prod1.hul.harvard.edu/science/article/pii/S0169207019302572), I decided that it would be worthwhile to see what they had to say. In total, I constructed 32 linear models and ran the seven states through them. I then evaluated the validity of each model and selected the best one for each state utilizing both in-sample and out-of-sample fit. R-squared measures in-sample fit or how well the model fits the given data. It can be thought of as the proportion of variability in the data captured by the given model. Root-mean-square error or RMSE measures out-of-sample fit or how good a given model is at making predictions based upon outside data. I attained the RMSE by performing leave-one-out cross-validation on all of my models which randomly removes an entry from the model, utilizes that entry to make a prediction, and then takes the difference between the actual and the predicted values calculating the error. In selecting a model for each state, the aim was a high R-squared but a low RMSE. I selected the model which had the best ratio between the two. All in all, even the best of my models do not reliably capture the state trends. Most notably, Texas has the smallest R-squared and the largest RMSE—not a good combo.

![](../figures/final_models.png)

Even though I included more complex models with interaction, the simpler ones emerged victorious. The models utilized variations of party, incumbency, incumbent party, election-year third quarter GDP growth, election-year unemployment, and election-year poll averages to predict popular vote share. Florida and Arizona settled on a multivariate model which uses election-year poll averages, party, incumbency, and incumbent party. The model that worked best for Georgia includes incumbent party and election-year unemployment. The best one for North Carolina, Iowa, and Texas also uses election-year unemployment but incumbency instead of incumbent party. Notably, Ohio's merely relies on election-year poll averages. Clearly missing is GDP growth entirely. The coefficients for party, incumbency, and incumbent party can be interpreted as the increase/decrease in popular vote associated with being a Republican, incumbent, or a member of the incumbent party. The coefficients for average poll and unemployment rate can be interpreted as the increase/decrease in popular vote associated with a one percentage point increase in either. When interpreting coefficients of multivariate models, they must be contextualized as the given association controlling for the other predictors.

![](../figures/final_models_plot.png)

![](../figures/final_estimate_plot.png)

In order to evaluate the models, I utilized leave-one-out cross-validation. The datasets were already quite small with some states only having 10 observations. Therefore, I was unable to use out-of-sample testing. To perform the cross-validation, I selected out a row from every state's data and created the respective models. Then, I used the model to predict the poll average for the selected row. By taking the difference between the prediction and the actual, I was able to find the error of the model. The errors are very state dependent, and it should be noted that leaving one out had different effects on different states due to the number of observations by state. The number of observations spanned from 10 to 202. At the same, error is not just dependent on the number of observations. Florida has the largest error and also has a relatively large number of observations at 61. Nevertheless, such an error could be from selecting an outlier row from the data for cross-validation.  

![](../figures/ec_total.png)

![](../figures/national_vote.png)

Is an increase in COVID deaths associated with lower poll numbers for Trump? Is an increase in COVID testing associated with higher numbers? **All in all, the jury is still out**. While the Montana, Kentucky, Maine, and Iowa slopes suggest that there is an inverse relationship between COVID deaths and Trump poll numbers, all other slopes hover close to zero including all of those for testing volume. For me to include COVID data in my election prediction, I will have to further tweak my models and determine a more robust relationship. Nevertheless, due to the current lack of a concrete relationship, **I doubt that I will include COVID data for all states within my final prediction model**.

All of my findings point to the fact that if Biden doesn't win, we shouldn't trust polls anymore.

*The polling data were sourced from FiveThirtyEight and can be found [here](#https://data.fivethirtyeight.com). All other data was sourced from the course's Canvas page. The code to replicate the above graphics can be found [here](https://github.com/SamuelLowry/gov1347_blog/blob/master/scripts/04-blog.R).*