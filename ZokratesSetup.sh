zokrates compile -i main.zok -o main --light --stdlib-path "..\zokrates\zokrates_stdlib"
zokrates setup -i main --light
zokrates export-verifier 