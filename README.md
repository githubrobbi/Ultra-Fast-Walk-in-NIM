# Ultra-Fast-Walk-in-NIM
os.Walk for NIM ... pretty fast ... UFFS is faster though :)

## COMPILE: 

```
nim c -d:danger --app:lib --opt:speed --gc:markAndSweep --out:ultra_fast_walk.pyd ultra_fast_walk.nim
```

This will give you a dynamic link library "ultra_fast_walk.pyd" for python

## Use in PYTHON:

```
import ultra_fast_walk as ufwlib

pys = ufwlib.walker(folderpath= "C:/") 
```



### Look in NIM source for all the available parameters of the "walker" function e.g. filter file-extensions etc.
