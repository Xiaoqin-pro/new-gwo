# Batch report: rd1c_20261016_135509

file: `runs.csv` | runs: 120 | reference: **GWO**

## Summary

| Algorithm     |   NRuns |   MeanErr |    MedianErr |   MeanRankFn |   MeanRankRun |   SecondsMean |   ImprovRate |
|:--------------|--------:|----------:|-------------:|-------------:|--------------:|--------------:|-------------:|
| E-f20-alpha-n |      40 | 1.32e+07  | 6491         |          1.5 |         1.775 |        0.9052 |     0.003209 |
| E-f30-alpha-r |      40 | 1.049e+07 | 4941         |          2   |         1.775 |        0.6457 |     0.002935 |
| GWO           |      40 | 2.577e+08 |    2.142e+04 |          2.5 |         2.45  |        0.5855 |     0.003072 |

## Pairwise vs reference

| Algorithm     | WL   |   FuncWins |   FuncLosses |   MedianRatio |   SigBetter |   SigWorse |    PooledP |   PooledLogDiff |
|:--------------|:-----|-----------:|-------------:|--------------:|------------:|-----------:|-----------:|----------------:|
| GWO           | ref  |        nan |          nan |      nan      |         nan |        nan | nan        |        nan      |
| E-f30-alpha-r |      |          4 |            4 |        0.7847 |         nan |        nan |   0.01063  |          0.1053 |
| E-f20-alpha-n |      |          5 |            3 |        0.7189 |         nan |        nan |   0.002771 |          0.1436 |

## Stagnation / recovery

| Algorithm     |   StagEpisodesTotal |   RecoveryProbWindow |   RecoveryProbEventual |   RecoveryMedExtraFE |   LongStagShare |   FinalStagLenMedian |   NImprove |   ImprovRateQ1 |   ImprovRateQ2 |   ImprovRateQ3 |   ImprovRateQ4 |
|:--------------|--------------------:|---------------------:|-----------------------:|---------------------:|----------------:|---------------------:|-----------:|---------------:|---------------:|---------------:|---------------:|
| GWO           |                 790 |               0.7747 |                 0.9924 |                501.8 |          0.8621 |                  7   |      92.17 |       0.003457 |      0.00082   |       0.00091  |       0.007103 |
| E-f30-alpha-r |                 766 |               0.7493 |                 0.9935 |                522.8 |          0.8559 |                  9   |      88.05 |       0.003387 |      0.00069   |       0.001197 |       0.006467 |
| E-f20-alpha-n |                 798 |               0.7669 |                 0.9962 |                568   |          0.8454 |                  7.5 |      96.28 |       0.003197 |      0.0008633 |       0.00114  |       0.007637 |

## Novelty

| Algorithm     |   NovMean |   NovMedian |   NovRate |   NovelUsefulRate |   NovelStrictImprove |   NovRateQ1 |   NovRateQ2 |   NovRateQ3 |   NovRateQ4 |
|:--------------|----------:|------------:|----------:|------------------:|---------------------:|------------:|------------:|------------:|------------:|
| GWO           |   0.04676 |     0.04221 |    0.8905 |          0.009498 |                 9.3  |           1 |      0.9996 |      0.9919 |      0.5703 |
| E-f30-alpha-r |   0.05782 |     0.04868 |    0.9296 |          0.01275  |                10.78 |           1 |      1      |      1      |      0.7186 |
| E-f20-alpha-n |   0.05607 |     0.04785 |    0.9262 |          0.01353  |                10.05 |           1 |      1      |      1      |      0.7047 |

## Median error ratio vs reference at checkpoints

| Algorithm     |   CheckT10 |   CheckT20 |   CheckT50 |   CheckT80 |   CheckT100 |
|:--------------|-----------:|-----------:|-----------:|-----------:|------------:|
| E-f30-alpha-r |      1.077 |      1.135 |      1.101 |     0.9282 |      0.8614 |
| E-f20-alpha-n |      1.047 |      1.11  |      1.015 |     0.9535 |      0.7631 |
