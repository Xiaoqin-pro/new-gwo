# Batch report: formal_20261016_140254

file: `merged_runs.csv` | runs: 13050 | reference: **GWO**

## Summary

| Algorithm     |   NRuns |   MeanErr |   MedianErr |   MeanRankFn |   MeanRankRun |   SecondsMean |   ImprovRate |
|:--------------|--------:|----------:|------------:|-------------:|--------------:|--------------:|-------------:|
| HIDMS-PSO     |     870 | 9.407e+04 |       662.6 |        2.517 |         3.275 |         3.316 |   nan        |
| HCLPSO        |     870 | 9.523e+04 |       697.3 |        3.172 |         3.732 |         2.126 |   nan        |
| DMS-PSO       |     870 | 1.131e+05 |       617.1 |        3.414 |         3.693 |         1.887 |   nan        |
| IGWO          |     870 | 1.617e+06 |       821.4 |        5.552 |         5.999 |         2.315 |   nan        |
| SAQ-CSO       |     870 | 2.469e+05 |       920.2 |        6.103 |         6.241 |         9.082 |   nan        |
| SPSO-2011     |     870 | 7.215e+05 |      1028   |        6.483 |         6.3   |         2.558 |   nan        |
| ANGWO-final   |     870 | 1.215e+07 |      1406   |        8.552 |         8.98  |         3.758 |     0.001587 |
| ANGWO-ES2     |     870 | 1.206e+07 |      1410   |        8.828 |         8.899 |         3.861 |     0.001583 |
| HPSO-TVAC     |     870 | 1.344e+05 |      1508   |        8.897 |         8.455 |         1.801 |   nan        |
| ANGWO-adapt   |     870 | 1.36e+07  |      1406   |        9     |         9.277 |         3.737 |     0.001738 |
| CLPSO         |     870 | 2.316e+06 |      1121   |        9.552 |         9.221 |         2.407 |   nan        |
| ANGWO-novdest |     870 | 1.518e+07 |      1428   |        9.931 |         9.291 |         4.942 |     0.001622 |
| GWO           |     870 | 2.648e+08 |      1812   |       11.45  |        10.84  |         3.627 |     0.001637 |
| ANGWO-self    |     870 | 3.116e+08 |      1840   |       11.59  |        10.96  |         3.761 |     0.001537 |
| Original-CSO  |     870 | 2.761e+09 |      7962   |       14.97  |        14.84  |         2.238 |   nan        |

## Pairwise vs reference

| Algorithm     | WL   |   FuncWins |   FuncLosses |   MedianRatio |   SigBetter |   SigWorse |      PooledP |   PooledLogDiff |
|:--------------|:-----|-----------:|-------------:|--------------:|------------:|-----------:|-------------:|----------------:|
| GWO           | ref  |        nan |          nan |      nan      |           0 |          0 | nan          |      nan        |
| ANGWO-final   |      |         21 |            8 |        0.7917 |           9 |          0 |   3.995e-40  |        0.1014   |
| ANGWO-self    |      |         13 |           16 |        1.013  |           0 |          0 |   0.09524    |       -0.005821 |
| ANGWO-novdest |      |         23 |            6 |        0.8301 |           8 |          0 |   2.062e-32  |        0.08087  |
| ANGWO-adapt   |      |         23 |            6 |        0.8247 |           8 |          0 |   1.227e-34  |        0.08371  |
| ANGWO-ES2     |      |         22 |            7 |        0.8071 |           9 |          0 |   1.539e-40  |        0.09309  |
| IGWO          |      |         27 |            2 |        0.4652 |          23 |          0 |   5.802e-105 |        0.3324   |
| HIDMS-PSO     |      |         29 |            0 |        0.3425 |          25 |          0 |   5.494e-135 |        0.4653   |
| HCLPSO        |      |         29 |            0 |        0.3967 |          24 |          0 |   2.091e-135 |        0.4015   |
| DMS-PSO       |      |         28 |            1 |        0.3887 |          27 |          0 |   5.464e-132 |        0.4104   |
| SAQ-CSO       |      |         29 |            0 |        0.5783 |          17 |          0 |   1.736e-104 |        0.2378   |
| SPSO-2011     |      |         26 |            3 |        0.5518 |          21 |          1 |   4.272e-98  |        0.2582   |
| HPSO-TVAC     |      |         17 |           12 |        0.7993 |          13 |          8 |   6.315e-32  |        0.0973   |
| CLPSO         |      |         21 |            8 |        0.7886 |          15 |          2 |   5.223e-42  |        0.1031   |
| Original-CSO  |      |          0 |           29 |        3.336  |           0 |         29 |   4.054e-142 |       -0.5232   |

## Stagnation / recovery

| Algorithm     |   StagEpisodesTotal |   RecoveryProbWindow |   RecoveryProbEventual |   RecoveryMedExtraFE |   LongStagShare |   FinalStagLenMedian |   NImprove |   ImprovRateQ1 |   ImprovRateQ2 |   ImprovRateQ3 |   ImprovRateQ4 |
|:--------------|--------------------:|---------------------:|-----------------------:|---------------------:|----------------:|---------------------:|-----------:|---------------:|---------------:|---------------:|---------------:|
| GWO           |           1.673e+04 |               0.7569 |                 0.9959 |                 1626 |          0.8441 |                    4 |      163.7 |       0.001213 |      0.0002075 |      0.000316  |       0.00481  |
| ANGWO-final   |           1.65e+04  |               0.7676 |                 0.995  |                 1611 |          0.8309 |                    6 |      158.7 |       0.001235 |      0.0002469 |      0.0003927 |       0.004474 |
| ANGWO-self    |           1.661e+04 |               0.7607 |                 0.9956 |                 1648 |          0.8471 |                    6 |      153.7 |       0.001183 |      0.0002154 |      0.0003191 |       0.004431 |
| ANGWO-novdest |           1.648e+04 |               0.7653 |                 0.9955 |                 1588 |          0.8295 |                    6 |      162.2 |       0.00122  |      0.0002417 |      0.0004089 |       0.004619 |
| ANGWO-adapt   |           1.642e+04 |               0.7669 |                 0.9956 |                 1567 |          0.828  |                    4 |      173.8 |       0.001243 |      0.0002422 |      0.0004252 |       0.005041 |
| ANGWO-ES2     |           1.644e+04 |               0.7664 |                 0.995  |                 1584 |          0.8321 |                    5 |      158.3 |       0.001234 |      0.0002471 |      0.0003924 |       0.004458 |
| IGWO          |           0         |             nan      |               nan      |                  nan |        nan      |                  nan |      nan   |     nan        |    nan         |    nan         |     nan        |
| HIDMS-PSO     |           0         |             nan      |               nan      |                  nan |        nan      |                  nan |      nan   |     nan        |    nan         |    nan         |     nan        |
| HCLPSO        |           0         |             nan      |               nan      |                  nan |        nan      |                  nan |      nan   |     nan        |    nan         |    nan         |     nan        |
| DMS-PSO       |           0         |             nan      |               nan      |                  nan |        nan      |                  nan |      nan   |     nan        |    nan         |    nan         |     nan        |
| SAQ-CSO       |           0         |             nan      |               nan      |                  nan |        nan      |                  nan |      nan   |     nan        |    nan         |    nan         |     nan        |
| SPSO-2011     |           0         |             nan      |               nan      |                  nan |        nan      |                  nan |      nan   |     nan        |    nan         |    nan         |     nan        |
| HPSO-TVAC     |           0         |             nan      |               nan      |                  nan |        nan      |                  nan |      nan   |     nan        |    nan         |    nan         |     nan        |
| CLPSO         |           0         |             nan      |               nan      |                  nan |        nan      |                  nan |      nan   |     nan        |    nan         |    nan         |     nan        |
| Original-CSO  |           0         |             nan      |               nan      |                  nan |        nan      |                  nan |      nan   |     nan        |    nan         |    nan         |     nan        |

## Novelty

| Algorithm     |   NovMean |   NovMedian |   NovRate |   NovelUsefulRate |   NovelStrictImprove |   NovRateQ1 |   NovRateQ2 |   NovRateQ3 |   NovRateQ4 |
|:--------------|----------:|------------:|----------:|------------------:|---------------------:|------------:|------------:|------------:|------------:|
| GWO           |   0.04791 |     0.04392 |    0.8966 |          0.003466 |                11.31 |           1 |           1 |      0.9987 |      0.5876 |
| ANGWO-final   |   0.05528 |     0.0499  |    0.9223 |          0.005783 |                13.55 |           1 |           1 |      0.9995 |      0.6895 |
| ANGWO-self    |   0.09819 |     0.05647 |    0.92   |          0.0059   |                11.65 |           1 |           1 |      0.9992 |      0.6809 |
| ANGWO-novdest |   0.05604 |     0.04973 |    0.9257 |          0.006484 |                14.06 |           1 |           1 |      0.9993 |      0.7035 |
| ANGWO-adapt   |   0.05213 |     0.04698 |    0.9071 |          0.00442  |                13.73 |           1 |           1 |      0.9988 |      0.6297 |
| ANGWO-ES2     |   0.05597 |     0.05033 |    0.9226 |          0.005703 |                13.35 |           1 |           1 |      0.9994 |      0.6911 |
| IGWO          | nan       |   nan       |  nan      |        nan        |               nan    |         nan |         nan |    nan      |    nan      |
| HIDMS-PSO     | nan       |   nan       |  nan      |        nan        |               nan    |         nan |         nan |    nan      |    nan      |
| HCLPSO        | nan       |   nan       |  nan      |        nan        |               nan    |         nan |         nan |    nan      |    nan      |
| DMS-PSO       | nan       |   nan       |  nan      |        nan        |               nan    |         nan |         nan |    nan      |    nan      |
| SAQ-CSO       | nan       |   nan       |  nan      |        nan        |               nan    |         nan |         nan |    nan      |    nan      |
| SPSO-2011     | nan       |   nan       |  nan      |        nan        |               nan    |         nan |         nan |    nan      |    nan      |
| HPSO-TVAC     | nan       |   nan       |  nan      |        nan        |               nan    |         nan |         nan |    nan      |    nan      |
| CLPSO         | nan       |   nan       |  nan      |        nan        |               nan    |         nan |         nan |    nan      |    nan      |
| Original-CSO  | nan       |   nan       |  nan      |        nan        |               nan    |         nan |         nan |    nan      |    nan      |

## Median error ratio vs reference at checkpoints

| Algorithm     |   CheckT10 |   CheckT20 |   CheckT50 |   CheckT80 |   CheckT100 |
|:--------------|-----------:|-----------:|-----------:|-----------:|------------:|
| ANGWO-final   |     1.011  |     1.008  |     0.9737 |     0.932  |      0.8759 |
| ANGWO-self    |     1.015  |     1.022  |     1.013  |     1.028  |      1.015  |
| ANGWO-novdest |     1.027  |     1      |     0.9937 |     0.9427 |      0.8737 |
| ANGWO-adapt   |     0.9912 |     0.9937 |     0.9677 |     0.9316 |      0.9008 |
| ANGWO-ES2     |     1.003  |     1.011  |     0.972  |     0.9359 |      0.8877 |
| IGWO          |   nan      |   nan      |   nan      |   nan      |    nan      |
| HIDMS-PSO     |   nan      |   nan      |   nan      |   nan      |    nan      |
| HCLPSO        |   nan      |   nan      |   nan      |   nan      |    nan      |
| DMS-PSO       |   nan      |   nan      |   nan      |   nan      |    nan      |
| SAQ-CSO       |   nan      |   nan      |   nan      |   nan      |    nan      |
| SPSO-2011     |   nan      |   nan      |   nan      |   nan      |    nan      |
| HPSO-TVAC     |   nan      |   nan      |   nan      |   nan      |    nan      |
| CLPSO         |   nan      |   nan      |   nan      |   nan      |    nan      |
| Original-CSO  |   nan      |   nan      |   nan      |   nan      |    nan      |
