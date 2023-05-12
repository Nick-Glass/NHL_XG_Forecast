# NHL_XG_Forecast
A time series forecast of a NHL player's expected goals for the 2022-23 season.

## AUTHOR
Nick Glass

## Overview
The goal of this project is to create a forecasting model to predict an NHL player's expected goals on a game level six games into the future. The data for this project came from the NHL API via the hockeyr scrape package. This data was used to create an expected goals model to predict whether a shot would become a goal on a play-by-play level. This model's output was then used to create this forecasting model using each game as the time period and the expected goals value as the prediction value. Each variable that was used in the expected goals model was shown in the EDA section of this project to show what goes into predicting the probability of scoring.

## Variable Dictionary:

- Faceoff Last - Was the previous event a faceoff? (TRUE or FALSE).

- Event Time Difference - The time between events in seconds.

- X Fixed - The fixed x coordinate corresponding to the location of the event on the rink from left to right with values of -99 to 99 in ft (Rink is 200ft long with 11ft behind each net).

- Y Fixed - The fixed y coordinate corresponding to the location of the event on the rink from bottom to top with values of -42 to 42 in ft (Rink is 85ft wide).

- Shot Distance - The distance in feet of the shot from the net.

- Shot Angle - The angle of the shot from the net.

- Score Difference - The difference in the score of a game.

- Rebound - Is the play a rebound? Defined as a shot on goal followed by a shot on goal or a goal by the same event team in the same period, within 3 seconds of each other (TRUE or FALSE).

- Rush Shot - Is the shot attempt off the rush? Defined as a shot on goal, a missed shot, or a goal, that occurred within 10 seconds of the opposing teams last shot attempt. (TRUE or FALSE).

- High Danger Attempt - Did the shot attempt occur in the slot? Defined as 30ft in front of the crease and 16ft wide between the faceoff circles. (TRUE or FALSE).

- High Danger Last - Was the last event a high danger attempt? (TRUE or FALSE).

- Strength - The strength of the event that occurred. (Even, Power Play, Short Handed, etc.)

- Secondary Type - The type of shot that occurred. (If the event is a missed shot than the secondary type is listed as missed shot).

- Is Goal - Did the event result in a goal? (This is the response variable, listed as 0 or 1).

- XG - The probability of a shot becoming a goal from the previous model.

## EDA:

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/8acf0674-4b8f-4c17-bac7-e4905d9ba395)

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/39b0ccf0-b0a4-4c06-bb7d-c8e3a4ff04f8)

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/c058b34e-dae2-4898-8f84-682e68153f5f)


Each event in the data set were grouped into their respective games and the total expected goals were then calculated at the game level for the player Kent Johnson. There were 34 unique games in the data. This is not ideal to have such a small sample size but due to the nature of the data generating process it was understandable. The training data was created using the first 23 games of the season and the testing data contained the data for the last 11 games.

One NHL player was isolated to model using a time series to find his expected goals over his next six games. The difference between the actual number of goals that Kent Johnson scored compared to the total predicted probability of his shot attempts was 1.67 goals. This was through his first 34 games of the season. Hopefully this prediction power translates to the time series analysis.

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/b89bd75c-4d9c-4e52-aa14-e9d32aebd5ee)


![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/ed3df62d-0949-485e-85aa-a3f316a3b589)


![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/fa40eeef-5ce5-450f-a681-d2401dac59b4)


![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/9335fc0d-ed36-4636-a209-d67960560512)


![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/b024ca7c-dd38-49c3-a27b-90fa8a4bffa5)


Looking at the above summary statistics it can be seen that the first date recorded for the training data was on October 10th 2022 and the last date recorded was December 21, 2022. During this span the average expected goals for Kent Johnson was around 0.19. The lowest expected goals value recorded was 0 and the highest was 0.52. Looking at the histogram it appears that in most games the player records between 0 and 0.2 expected goals. Furthermore, the box plot shows that there are no major outliers in the data. These plots back up the inferences made by the summary statistics. There were no missing values in the data.

The above line plot shows Kent Johnson’s expected goals over each game of the season so far. It can be seen that there are some games where the XG value is much higher than others. This could be directly related to the variables used in the model shown in the EDA process. Each one of these predictors tell a great amount when it comes to explaining a player's scoring pattern. The purpose of using the forecast is to get an idea of where the player is headed in terms of scoring. Expected goals are a great way to see a player's overall contribution to his team's offense. It would be valuable to see how the player would be expected to perform in the future.

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/ec053877-5e63-4c76-84aa-f47c47df06d9)


![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/51a980ba-02f6-41d1-9296-df96b912322f)


Looking at the trend there does not seem to be any pattern over the season so far. This could be because of the nature of the sport or the lack of extensive data for this model. Looking at the remainder there could be some white noise in the data or maybe the model is not capturing the full trend of the data. This data will not have seasonality due to being from independent games throughout the NHL season.

Using a ma 5 center we can see that the trend is smooth enough that the forecast would not be heavily affected by the peaks in the data but also captures the overall trend. The last two values and next two values of each game were used to model this trend. It does not follow the peaks and valleys of the data too closely indicating that the model is not as susceptible to the variability in the data.

## Create an ARIMA model:

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/0fbe9a81-d70c-49aa-8ab7-08c4a5005cfb)

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/9941f88e-a1f0-4c4d-ab90-f8de41a54348)

Looking at the above plot it appears the data is mean stationary because the peaks and valleys of the trend seem like they revolve around 0.2 XG. There might not be enough data to see if the trend is variance stationary or not. This might not be an issue because we applied a log transformation to the data anyway to make sure there were no negative values. This would take care of any non stationary variance in the model. The data is also between 0 and 1 so the variance should not be an issue.

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/77b2c0dd-a0e8-467d-8afe-17baa607504f)

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/da92837c-914e-426e-968a-2816ea5537bf)

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/a33a08df-9175-42ed-b460-01f1ffa4dc25)

We can see from the KPSS test that both the raw expected goals trend and the log XG value were stationary. This could be seen by examining the p-value. If the p-value where greater than 0.05 then the data is stationary. In this case the p-value was 0.1. On the ADF test the p-value was less then 0.05 meaning that the data was stationary. The log of the expected goals value was taken because the probabilities can not be negative. This could also help correct any variance non stationary issues in the model.

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/27883a13-7b01-43d6-a6bd-e741440b84b2)

Looking at the ACF and PACF plots we can see that none of the lag values were significant meaning that there was not any autocorrelation in the data. There appears to be one significant lag in the PACF plot at lag 4 but this was probably random. A log is considered significant when it crosses the dotted line. This shows that the model is most likely white noise and that we can not retrieve any parameters from the plots.

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/8a7358f2-cd8a-4fda-8a7d-e7c1e5f67f43)

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/6e44b824-f2e8-4690-bca8-c7a98c886f6c)

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/ad6fc30d-36aa-4d33-b578-1c56b3aeb6fb)

After using the automatic model selection and running other specified models we can see that the best model was the white noise. We could identify the best model by looking for the lowest AIC and BIC. The white noise model chosen had the lowest value for both of these criteria. This means that the expected goals values from one game were independent from the other games. This is an interesting find even though it seems like we can not accurately forecast future games expected goals. It is worth noting that if there were more data we might get better results.

Looking at the residuals we can see that there wasn’t any clear pattern. This makes sense because we are dealing with a model that contains a lot of white noise so there should not be any clear pattern in the residuals.

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/e0ac7350-62af-4038-9186-ce457f752c1d)

When looking at the ljung_box lag 1 we can see that the p-value was 0 showing it was significant. This means that the model at this lag did not show any autocorrelation. Conversely, the test at lag 3 and lag 5 were not significant meaning there was some autocorrelation in the model. This was interesting to note that different lags have different levels of autocorrelation.

## Create prophet model:

Prophet models take into account seasonality and special dates such as holidays when modeling trends. Unlike ARIMA models, prophet models do not need to be mean or variance stationary before forecasting the trend. We also do not need to use ACF/PACF plots in these types of models but we still would like to understand the data generating process. These forecasting methods essentially just model the trend of the data. If the data does not contain seasonality the model is basically a curve fitter.

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/cdfaf319-18ca-462b-a19a-c14f83bd01b0)


The model chosen for the prophet model was less flexible than a standard model and was adjusted to add a floor and cap parameters to the forecast since the expected goals could not be negative. This was achieved by specifying a logistic trend in the model. The forecast did not include any change points which was expected due to the lack of data points and the nature of the data generating process. Furthermore, there was not any seasonality in the data so the model was adjusted accordingly. No special dates or holidays were specified in the model because each game of the season should be equally weighted in terms of the players performance. This model had a slight upward trend and looked reasonable graphically since we would expect a player to get better as the season goes on. The fact that this model looked like it adjusts for the increase in expected goal values was promising.

## Comparing Models:

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/0ca9b036-4539-437f-ba18-7d84ac9a8a45)


![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/d10476fa-5432-4e8c-b6d0-64cb065ffc8d)


![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/6e6557a7-faf8-407e-a4a9-c36f73a9c41a)


Looking at the cross validation plots it can be seen that the three models were very different in predicting the expected goals values throughout the training data. The prophet model seemed to be the the worst in terms of following the trend of the data. The ARIMA model always predicted a flat trend indicating that the model can not accurately predict the future expected goals values. The naive model seemed to be a little better than the prophet model but maybe a little worse than the ARIMA model. Again these models moght preform much better with more data.

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/66791805-766e-4dba-b220-5914e840fe53)

![image](https://github.com/Nick-Glass/NHL_XG_Forecast/assets/113626253/04a3c038-67a5-46dd-8444-13482396fb41)

Looking at the RMSE as the forecast progressed we can see that the overall lowest error was from the ARIMA model. The prophet model had the overall highest error throughout the forecast of the three models. The naive model preformed better than the prophet model and a little worse than the ARIMA model. The forecast for the ARIMA model predicted a flat trend for the next 6 games. It is worth remebering that the best ARIMA model was white noise so this indicates that non of these models can accurately forecast expected goals into the future games. Again this does not mean the data generating process is completely random from game to game. It would be worth exploring these same techniques with more data to truly understand if expected goals are random from game to game.
