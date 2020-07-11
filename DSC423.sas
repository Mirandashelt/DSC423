proc format noprint;
    value $main_category_num_var
        Food = 1
        Games = 2
        Photography = 3
        Art = 4
        Fashion = 5
        'Film & Video' = 6
        Music = 7
        Technology = 8
        Publishing = 9
        Crafts = 10
        Comics = 11
        Design = 12
        Dance = 13
        Journalism = 14
        Theater = 15
    ;
run;
* Read in the csv, dsd -> ignore commas within fields;
* Filter on country and currency;
* Drop unused columns from dataset;
data kickstart_data REPLACE;
infile "S:\Project\ks-projects-201801.csv" delimiter =',' missover firstobs=2 dsd LRECL=10000;
input ID name :$75. category :$50. main_category :$50. currency $ deadline :yymmdd10. goal launched :yymmdd10. pledged state :$10. backers country $ usd_pledged usd_pledged_real usd_goal_real;
if country in ("US") and currency in ("USD");
if state in ('successful', 'failed');
timeline = deadline - launched;
d_state = 0;
if state = "successful" then d_state = 1;
d_main_category = input(put(main_category, $main_category_num_var.), 3.);
d_food = 0;
if main_category = 'Food' then d_food = 1;
d_games = 0;
if main_category = 'Games' then d_games = 1;
d_photography = 0;
if main_category = 'Photography' then d_photography = 1;
d_art = 0;
if main_category = 'Art' then d_art = 1;
d_fashion = 0;
if main_category = 'Fashion' then d_fashion = 1;
d_film_video = 0;
if main_category = 'Film & Video' then d_film_video = 1;
d_music = 0;
if main_category = 'Music' then d_music = 1;
d_technology = 0;
if main_category = 'Technology' then d_technology = 1;
d_publishing = 0;
if main_category = 'Publishing' then d_publishing = 1;
d_crafts = 0;
if main_category = 'Crafts' then d_crafts = 1;
d_comics = 0;
if main_category = 'Comics' then d_comics = 1;
d_design = 0;
if main_category = 'Design' then d_design = 1;
d_dance = 0;
if main_category = 'Dance' then d_dance = 1;
d_journalism = 0;
if main_category = 'Journalism' then d_journalism = 1;
d_theater = 0;
if main_category = 'Theater' then d_theater = 1;
log_goal = log(goal);
*log_pledged = log(pledged);  * pledged values might be zero, can't log;
*log_usd_pledged = log(usd_pledged);
*log_usd_pledged_real = log(usd_pledged_real);
log_usd_goal_real = log(usd_goal_real);
log_timeline = log(timeline);

*Transform sqrt;
sqrt_backers = sqrt(backers);
sqrt_pledged = sqrt(pledged);
sqrt_usd_pledged = sqrt(usd_pledged);
sqrt_usd_pledge_real = sqrt(usd_pledged_real);

*Transform sq;
sq_backers = backers**2;
sq_pledged = pledged**2;
sq_usd_pledged = usd_pledged**2;
sq_usd_pledge_real = usd_pledged_real**2;

*log_backers = log(backers);
*interaction variable;
pledged_backers = log(pledged*backers);

drop country currency category ID name deadline launched;
run;
* Create random sample of 3000 records;
PROC SURVEYSELECT DATA = kickstart_data OUT = kickstart_data_sample seed=1234567
METHOD = SRS NOPRINT
N = 3000 ;
RUN ;
* Create training set;
proc surveyselect data=kickstart_data_sample out=kickstart_train seed=495857
n=2500
outall;
run;
* Create test set;
data kickstart_train;
set kickstart_train;
if selected then train_y=d_state;
run;
proc contents data=kickstart_train;
run;
proc print data=kickstart_train;
run;
* Scatterplots;
proc sgscatter data=kickstart_train;
title "Scatterplot Matrix";
*matrix d_state d_main_category goal pledged backers usd_pledged usd_pledged_real usd_goal_real timeline d_food d_games d_photography d_art d_fashion d_film_video d_music d_technology d_publishing d_crafts d_comics d_design d_dance d_journalism d_theater;
matrix pledged_backers d_state d_main_category goal log_goal pledged backers usd_pledged usd_pledged_real usd_goal_real log_usd_goal_real timeline log_timeline;
run;
* Histograms;
PROC means data=kickstart_train
min max median p25 p75;
var goal;
run;
proc univariate normal data=kickstart_train;
title "Histogram";
var pledged_backers d_main_category goal log_goal pledged backers sqrt_backers sq_backers usd_pledged sqrt_pledged sq_pledged usd_pledged_real sqrt_usd_pledged sq_usd_pledge usd_goal_real log_usd_goal_real sqrt_usd_pledge_real sq_usd_pledge_real timeline log_timeline;
histogram / normal (mu = est sigma = est);
run;
* Boxplots;
* sort;
proc sort data = kickstart_data_sample;
by time_numeric;
run;
proc boxplot;
plot Temperature_c*time_numeric;
run;
* Distributions;
proc freq data=kickstart_train;
tables d_state;
run;
proc freq data=kickstart_train;
tables d_main_category;
run;
* Correlations;
proc corr data=kickstart_train;
var d_state pledged_backers log_goal sqrt_pledged sqrt_backers sqrt_usd_pledged sqrt_usd_pledge_real log_usd_goal_real timeline d_food d_games d_photography d_art d_fashion d_film_video d_music d_technology d_publishing d_crafts d_comics d_design d_dance d_journalism d_theater;
run;

* Residuals;
* Interactions;
* VIF;
proc logistic data=kickstart_train; 
model train_y(event='1')=pledged_backers log_goal sqrt_pledged sqrt_backers sqrt_usd_pledged sqrt_usd_pledge_real log_usd_goal_real timeline d_food d_games d_photography d_art d_fashion d_film_video d_music d_technology d_publishing d_crafts d_comics d_design d_dance d_journalism d_theater/ stb corrb influence iplots; 
run;


* Model Selection;
proc logistic data=kickstart_train;
title "Stepwise";
model train_y(event='1') = pledged_backers log_goal sqrt_pledged sqrt_backers sqrt_usd_pledged sqrt_usd_pledge_real log_usd_goal_real timeline d_food d_games d_photography d_art d_fashion d_film_video d_music d_technology d_publishing d_crafts d_comics d_design d_dance d_journalism d_theater / selection= stepwise stb rsquare;
run;
proc logistic data=kickstart_train;
title "Forward";
model train_y(event='1') = pledged_backers log_goal sqrt_pledged sqrt_backers sqrt_usd_pledged sqrt_usd_pledge_real log_usd_goal_real timeline d_food d_games d_photography d_art d_fashion d_film_video d_music d_technology d_publishing d_crafts d_comics d_design d_dance d_journalism d_theater / selection= forward stb rsquare;
run;
proc logistic data=kickstart_train;
title "Backward";
model train_y(event='1') = pledged_backers log_goal sqrt_pledged sqrt_backers sqrt_usd_pledged sqrt_usd_pledge_real log_usd_goal_real timeline d_food d_games d_photography d_art d_fashion d_film_video d_music d_technology d_publishing d_crafts d_comics d_design d_dance d_journalism d_theater / selection= backward stb rsquare;
run;
*proc logistic data=kickstart_train;
*title "Score";
*model train_y(event='1') = pledged_backers log_goal sqrt_pledged sqrt_backers sqrt_usd_pledged sqrt_usd_pledge_real log_usd_goal_real timeline d_food d_games d_photography d_art d_fashion d_film_video d_music d_technology d_publishing d_crafts d_comics d_design d_dance d_journalism d_theater / selection= score stb rsquare;
*run;


* Correlations;
proc corr data=kickstart_train;
var pledged_backers log_goal sqrt_backers sqrt_pledged d_games d_technology d_comics;
run;

proc logistic data=kickstart_train; 
model train_y(event='1')=pledged_backers log_goal sqrt_backers sqrt_pledged d_games d_technology d_comics/ stb corrb influence iplots; 
run;

* Outliers/Influencers;
proc reg data=kickstart_train;
title "Residuals";
model d_state = pledged_backers log_goal sqrt_backers sqrt_pledged d_games d_technology d_comics;
plot npp.*student.;
run;
proc reg data=kickstart_train;
model d_state = pledged_backers log_goal sqrt_backers sqrt_pledged d_games d_technology d_comic / influence r;
run;


* VIF;
proc reg data=test;
model d_state = goal pledged backers usd_pledged timeline d_food d_games d_art d_fashion d_film_video d_technology d_publishing d_crafts d_comics d_design d_journalism / vif stb;
run;
proc reg data=test;
model d_state = goal pledged backers timeline d_food d_games d_art d_fashion d_film_video d_technology d_publishing d_crafts d_comics d_design d_journalism / vif stb;
run;
* Outliers;
proc reg;
model d_state = goal pledged backers timeline d_food d_games d_art d_fashion d_film_video d_technology d_publishing d_crafts d_comics d_design d_journalism / influence r;
run;
* fit the final model, compute predicted probability;
* based on model built using the training set, compute the;
* predicted probability for test set;
proc logistic data=kickstart_train; 
model train_y(event='1' )=sediments d_meander1;
* output results to dataset called pred;
* predicted value is written to variable --> phat ;
output out=pred(where=(train_y=.))  p=phat lower=lcl upper=ucl predprob=(individual);
run;