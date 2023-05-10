## load packages
library(tidyverse)
library(GGally)
library(viridis)
library(knitr)
library(kableExtra)
library(quarto)
library(rmarkdown)
library(gapminder)
library(janitor)
library(lubridate)
library(scales)
library(gt)
library(patchwork)
library(data.table)
library(corrplot)
library(zoo)
library(forecast)
library(feasts)
library(fable)
library(tsibble)
library(tseries)
library(prophet)
library(htmltools)
library(fable.prophet)

## load data
pbp23 <- read_csv("XG_Final_23.csv")

## subset data to include only necessary variables
XG_Final <- pbp23 %>%
  select(Date_Time,Season,Season_Type,Game_Id,Period,Event_Idx,Event,
         Event_Player_1_FullName,Event,Secondary_Type,Strength,
         Empty_Net,X_Fixed:Shot_Angle,Last_Event:Rebound,Rush_Shot:XG) %>%
  mutate_if(is.character, factor) %>%
  mutate_if(is.logical, factor) %>%
  arrange(Game_Id,Period,Event_Idx)

## get player of interest
Kent_Johnson <- XG_Final %>%
  ungroup() %>%
  group_by(Game_Id,Date_Time,XG) %>%
  filter(Event_Player_1_FullName == "Kent Johnson") 

## compare XG to actual goals
Kent_Johnson %>%
  ungroup() %>%
  rename(Player = Event_Player_1_FullName) %>%
  group_by(Player) %>%
  summarise(Expected_Goals = sum(XG),
            Actual_Goals = sum(Is_Goal)) %>%
  mutate(XG_Difference = abs(Actual_Goals - Expected_Goals)) %>%
  dplyr::select(Player,Expected_Goals,
                Actual_Goals,XG_Difference) %>%
  arrange(desc(Expected_Goals)) %>%
  kbl(caption = "Table Showing Actual Goals vs Expected Goals") %>%
  kable_classic(full_width = F, html_font = "Cambria",font_size = 12)

## create sequence 
Game <- 1:34

Game_df <- data.frame(Game)

## create df by for XG by game
Kent_Johnson_df <- Kent_Johnson %>%
  group_by(Game_Id) %>%
  mutate(Game_Date = as.Date(Date_Time), "%YYYY-%MM-%DD") %>%
  summarise(XG = sum(XG),
            Game_Date = Game_Date) %>%
  filter(!duplicated(Game_Id))

## add seq to data frame
Kent_Johnson_df <- cbind(Game_df,Kent_Johnson_df)
glimpse(Kent_Johnson_df)

## add prophet variables
Kent_Johnson_df <- Kent_Johnson_df %>%
  mutate(y = XG,
         ds = Game_Date)

## split data
## train
KJ_train = Kent_Johnson_df %>%
  filter(Game_Date<ymd("2022-12-24"))

## test
KJ_test = Kent_Johnson_df %>%
  filter(Game_Date>=ymd("2022-12-24"))

## look at training data
glimpse(KJ_train)

# EDA ---------------------------------------------------------------------
## double check NA values 
sort(colSums(is.na(KJ_train)), decreasing = TRUE) %>%
  kbl(caption = "Table Showing Missing Values") %>%
  kable_classic(full_width = F, html_font = "Cambria",font_size = 12)

## summary statistics
summary(KJ_train) %>%
  kbl(caption = "Table Showing Summary Statistics") %>%
  kable_classic(full_width = T, html_font = "Cambria",font_size = 12)

## find standard deviation for each variable
sort(sapply(KJ_train, sd, na.rm = TRUE), decreasing = TRUE) %>%
  kbl(caption = "Table Showing Standard Deviation") %>%
  kable_classic(full_width = F, html_font = "Cambria",font_size = 12)

## plot histogram of expected goals
ggplot(KJ_train, aes(x = XG)) +
  ggtitle("Expected Goals for Kent Johnson") +
  labs(x="XG", y="Count", fill="XG",
       subtitle = "Most of the games Kent Johnson played had an expected goals value bellow 20%.",
       caption = "Data source: NHL API") +
  geom_histogram(color = "#00d100", fill="#24ff24",alpha=0.95) + labs(title = "Kent Johnson Expected Goals 2023") +
  theme(plot.title = element_text(family="Arial", color="black", size=14, face="bold.italic"),
        axis.title.x=element_text(family="Arial", face="plain", color="black", size=14),
        axis.title.y=element_text(family="Arial", face="plain", color="black", size=14),
        axis.text.x=element_text(family="Arial", face="bold", color="black", size=8),
        axis.text.y=element_text(family="Arial", face="bold", color="black", size=8),
        panel.background=element_rect(fill="white"),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank())

## plot box plot of expected goals
ggplot(KJ_train, aes(x = factor(0),y = XG)) +
  ggtitle("Expected Goals for Kent Johnson") +
  labs(x="XG", y="Count", fill="XG",
       subtitle = "There does not appear to be any major outliers in the data.",
       caption = "Data source: NHL API") +
  geom_boxplot(color = "#00d100", fill="#24ff24",alpha=0.95) + labs(title = "Kent Johnson Expected Goals 2023") +
  theme(plot.title = element_text(family="Arial", color="black", size=14, face="bold.italic"),
        axis.title.x=element_text(family="Arial", face="plain", color="black", size=14),
        axis.title.y=element_text(family="Arial", face="plain", color="black", size=14),
        axis.text.x=element_blank(),
        axis.text.y=element_text(family="Arial", face="bold", color="black", size=8),
        panel.background=element_rect(fill="white"),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank())

## Kent Johnson XG through the season so far
KJ_train %>%
  ggplot(aes(x=Game_Date,y=XG)) +                 
  geom_line(color="blue",alpha=0.9) +
  ggtitle("Expected Goals by Game for Kent Johnson") +
  labs(x="Game", y="XG", fill="XG",
       subtitle = "XG value by game for Kent Johnson seem to go up and down by game. \nThis is expected for a player to have good games and bad games throughout the season.",
       caption = "Data source: NHL API") +
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))


## moving average
KJ_decomp <- KJ_train %>%
  as_tsibble(index = Game) %>%
  mutate(
    ma_5_center = rollapply(
      XG,
      5,
      FUN = mean,
      align = "center", fill = NA
    )
    
  ) %>%
  mutate(resid = XG - ma_5_center) %>%
  select(Game, XG, ma_5_center, resid)

KJ_decomp_plot <- KJ_decomp %>%
  pivot_longer(
    XG:resid,
    names_to = "decomposition",
    values_to = "XG"
  ) %>%
  mutate(
    decomposition = case_when(
      decomposition == "XG" ~ "Expected Goals",
      decomposition == "ma_5_center" ~ "Trend",
      decomposition == "resid" ~ "Remainder"
    )
  ) %>%
  mutate(
    decomposition = factor(
      decomposition,
      labels = c(
        "Expected Goals",
        "Trend",
        "Remainder"
      ),
      levels = c(
        "Expected Goals",
        "Trend",
        "Remainder"
      )
    )
  ) %>%
  ggplot() +
  geom_line(aes(Game, XG), size = 1) +
  facet_wrap(
    ~decomposition,
    nrow = 3,
    scales = "free"
  ) +
  theme_bw() +
  ylab("") +
  xlab("Game") +
  ggtitle(
    "Expected Goals = Trend + Remainder"
  )

KJ_decomp_plot

## ma 5
KJ_decomp %>%
  drop_na() %>%
  mutate(
    new_remainder = sample(resid, replace = F),
    new_XG = ma_5_center + new_remainder
  ) %>%
  ggplot() +
  geom_line(aes(Game, XG)) +
  geom_line(aes(Game, ma_5_center), color = "blue") +
  #geom_line(aes(Game, ma_5_Left), color = "green") +
  #geom_line(aes(Game, ma_5_Right), color = "purple") +
  #geom_line(aes(Game, new_XG), color = "red")+
  ggtitle("Expected Goals MA 5 for Kent Johnson") +
  labs(x="Game", y="XG", fill="XG",
       subtitle = "XG value by game for Kent Johnson modeled by a moving average 5 center in blue \nvs the actual value in black. The data is for the first 34 games of the 2023 season.",
       caption = "Data source: NHL API") +
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))

## create rolling average & sd
KJ_roll <- KJ_train %>%
  mutate(
    XG_mean = zoo::rollmean(
      log1p(XG), 
      k = 3, 
      fill = NA),
    XG_sd = zoo::rollapply(
      log1p(XG), 
      FUN = sd, 
      width = 3, 
      fill = NA)
  )

## plot rolling average
KJ_rollmean <- KJ_roll %>%
  ggplot() +
  geom_line(aes(Game, XG)) +
  geom_line(aes(Game, XG_mean),color='blue') +
  ggtitle("XG Mean Values Over Each Game") +
  ylab("XG") +
  xlab("Game") +
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))


KJ_rollmean

## plot rolling sd
KJ_rollsd <- KJ_roll %>%
  ggplot() +
  geom_line(aes(Game, XG_sd)) +
  geom_smooth(aes(Game,XG_sd),method='lm',se=F)+
  ggtitle("XG SD Values Over Each Game") +
  ylab("XG") +
  xlab("Game") +
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))


KJ_rollsd

## log the data
KJ_log <- KJ_train %>%
  mutate(
    KJ_log = log1p(XG)) %>%
  drop_na() %>%
  as_tsibble(index=Game)

## plot the log of XG
KJ_log %>%
  ggplot() +
  geom_line(aes(Game, KJ_log)) +
  theme_bw() +
  ggtitle("XG (Log)") +
  ylab("Log Transformed XG") +
  xlab("Game") +
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))


# Raw close value - Non-stationary
raw_value_kpss = KJ_log %>% 
  features(XG, unitroot_kpss)

raw_value_kpss %>%
  kbl(caption = "Table Showing KPSS Values") %>%
  kable_classic(full_width = F, html_font = "Cambria",font_size = 12)

# Log close value - Non-stationary
log_value_kpss = KJ_log %>%
  features(KJ_log, unitroot_kpss)

log_value_kpss %>%
  kbl(caption = "Table Showing KPSS Values") %>%
  kable_classic(full_width = F, html_font = "Cambria",font_size = 12)

adf.test(KJ_log$KJ_log)


## check ACF plot
acf = KJ_log %>%
  fill_gaps() %>%
  ACF(KJ_log,lag_max=10) %>%
  autoplot() + 
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))

## check PACF plot
pacf =  KJ_log %>%
  fill_gaps() %>%
  PACF(KJ_log) %>%
  autoplot() +
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))


acf + pacf

## run best guess models
models_bic = KJ_log %>%
  fill_gaps() %>%
  model(
    mod1 = ARIMA(log1p(XG)~pdq(0,0,0)+PDQ(0,0,0)),
    mod2 = ARIMA(log1p(XG)~pdq(0,1,1)+PDQ(0,0,0)),
    mod3 = ARIMA(log1p(XG)~pdq(1,1,0)+PDQ(0,0,0)),
    mod4 = ARIMA(log1p(XG)~pdq(2,1,0)+PDQ(0,0,0)),
    mod5 = ARIMA(log1p(XG)~pdq(0,1,0)+PDQ(0,0,0)),
    mod6 = ARIMA(log1p(XG)~pdq(0,1,2)+PDQ(0,0,0))
  )

## show model results
models_bic %>%
  glance() %>%
  arrange(BIC) %>%
  kbl(caption = "Table Showing Model Results") %>%
  kable_classic(full_width = T, html_font = "Cambria",font_size = 10)

## automatically pick best model
ARIMA_model = KJ_log %>%
  fill_gaps() %>%
  model(
    ARIMA(log1p(XG),approximation=F) # Didn't set stepwise here because of size of the data
  )%>%
  report()
## show residuals
ARIMA_model %>%
  gg_tsresiduals()

## ljung_box lag 1
ARIMA_model %>%
  augment() %>%
  features(.innov, ljung_box, lag = 1, dof = 1) %>%
  kbl(caption = "ljung_box lag 1") %>%
  kable_classic(full_width = F, html_font = "Cambria",font_size = 12)

## ljung_box lag 3
ARIMA_model %>%
  augment() %>%
  features(.innov, ljung_box, lag = 3, dof = 1) %>%
  kbl(caption = "ljung_box lag 3") %>%
  kable_classic(full_width = F, html_font = "Cambria",font_size = 12)

## ljung_box lag 5
ARIMA_model %>%
  augment() %>%
  features(.innov, ljung_box, lag = 5, dof = 1) %>%
  kbl(caption = "ljung_box lag 5") %>%
  kable_classic(full_width = F, html_font = "Cambria",font_size = 12)


## prophet model
prophet_data = Kent_Johnson_df %>% 
  select(ds,y)

train = prophet_data %>%  # Train set
  filter(ds<ymd("2022-12-24"))

test = prophet_data %>% # Test set
  filter(ds>=ymd("2022-12-24"))

## less flexible model
prophet_model = prophet::prophet(train,changepoint.prior.scale=0.001,weekly.seasonality = FALSE)

# Create future dataframe for predictions
less_flex_future = make_future_dataframe(prophet_model,periods = 12)

## create forecast
less_flex_forecast = predict(prophet_model,less_flex_future)

## Set "floor" in training data
train$floor = 0
train$cap = 2
less_flex_future$floor = 0
less_flex_future$cap = 2

## Set floor in forecsat data
less_flex_forecast$floor = 0
less_flex_forecast$cap = 2
sat_prophet_model = prophet::prophet(train,growth='logistic',
                                     weekly.seasonality = FALSE)

# Create future dataframe for predictions
sat_future = make_future_dataframe(sat_prophet_model,periods = 12) 


## create forecast
sat_forecast = predict(sat_prophet_model,less_flex_forecast)


## plot change points
plot(sat_prophet_model,sat_forecast)+add_changepoints_to_plot(sat_prophet_model)+xlab("Game Date")+ylab("XG")+
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))


## decomposition
prophet_plot_components(sat_prophet_model,sat_forecast)

## cross validation
cv_data = KJ_train %>%
  as_tsibble(index = Game_Date) %>%
  stretch_tsibble(.init = 3, .step = 1) %>%
  relocate(Game_Date, XG, y, Game, ds)

## plot cross validation
cv_data %>%
  ggplot()+
  geom_point(aes(Game,factor(.id),color=factor(.id)))+
  ylab('Iteration')+
  ggtitle('Samples included in each CV Iteration') +
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))


## compare forecasts
Model_Comp <- cv_data %>%
  fill_gaps() %>%
  model(
    arima = ARIMA(log1p(y)~pdq(0,0,0)+PDQ(0,0,0)),
    prophet = prophet(log1p(y)~growth("linear")),
    naive = NAIVE(log1p(y)) 
  )%>%
  forecast(h = 6)

## plot comparing forecasts
Model_Comp %>%
  forecast::autoplot(cv_data)+
  facet_wrap(~.id,nrow=4)+
  theme_bw()


## plot cross validation
Model_Comp %>%
  as_tsibble() %>%
  select(-y) %>%
  left_join(
    KJ_train
  ) %>%
  ggplot()+
  geom_line(aes(Game,XG))+
  geom_line(aes(Game,.mean,color=factor(.id),linetype=.model))+
  scale_color_discrete(name='Iteration')+
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))


## convert to a tsibble
KJ_train <- KJ_train %>%
  as_tsibble(index = Game_Date) 

## Compare error metrics
Model_Comp %>%
  group_by(.id) %>%
  accuracy(KJ_train) %>%
  ungroup() %>%
  data.table() %>%
  kbl(caption = "Coss Validation Metrics") %>%
  kable_classic(full_width = F, html_font = "Cambria",font_size = 12)

## compare RMSE
Model_Comp %>%
  group_by(.id,.model) %>%
  mutate(h = row_number()) %>%
  ungroup() %>%
  as_fable(response = "XG", distribution = y) %>%
  accuracy(KJ_train, by = c("h", ".model")) %>%
  ggplot(aes(x = h, y = RMSE,color=.model)) +
  geom_point()+
  geom_line()+
  ylab('Average RMSE at Forecasting Intervals')+
  xlab('Games in the Future')+
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))


## forecast the final model
ARIMA_model %>%
  forecast(h=12) %>%
  autoplot(KJ_train %>%
             bind_rows(KJ_test))+
  ylab('XG')+
  ggtitle('ARIMA Forecast')+
  theme(plot.title = element_text(family="Arial",color="black",size=14,face="bold.italic"),
        axis.title.y=element_text(family="Arial",face="plain",color="black",size=14),
        legend.title = element_text(family="Arial",face="bold",colour="black",size=10),
        axis.text.y=element_text(family="Arial",face="bold",color="black",size=8),
        panel.margin=unit(0.05, "lines"),
        panel.border = element_rect(color="black",fill=NA,size=1), 
        strip.background = element_rect(color="black",fill="white",size=1),
        axis.title.x=element_text(family="Arial",face="plain",color="black",size=14),
        axis.text.x=element_text(family="Arial",face="bold",color="black",size=8),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor = element_blank(),
        axis.ticks=element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = "white"))

