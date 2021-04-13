
install:
	cd ..
	git clone https://github.com/ZoKrates/ZoKrates --branch 0.6.2
	cd ZoKrates
	cargo +nightly build --release
	cd ..

setup:
	zokrates compile -i main.zok -o main --light --stdlib-path "..\zokrates\zokrates_stdlib"
	zokrates setup -i main --light
	zokrates export-verifier 

generate-sample:
	zokrates compute-witness -i main -a 15 1 50 15 1 50 15 1 50 0 0 0 0 0 0 0 0 0 0 0 0 10 1 75 10 1 75 10 1 75 0 0 0 0 0 0 0 0 0 0 0 0 3
	zokrates generate-proof -i main
	zokrates verify