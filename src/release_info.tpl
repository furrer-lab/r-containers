# Configuration

```{r echo=FALSE, results='markup'}
print(sessionInfo())
```

# Installed packages

```{r echo=FALSE, results='markup'}
ip=as.data.frame(installed.packages()[,c(1,3:4)])
knitr::kable(ip[is.na(ip$Priority),1:2,drop=FALSE][2])
```
