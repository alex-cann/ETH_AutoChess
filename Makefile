
install:
	cd ..
	git clone https://github.com/ZoKrates/ZoKrates --branch 0.6.2
	cd ZoKrates
	cargo +nightly build --release
	cd ..

setup:
	zokrates.exe compile -i main.zok -o main --light --stdlib-path "..\zokrates\zokrates_stdlib"
	zokrates.exe setup -i main --light
	zokrates.exe export-verifier 

generate-sample:
	zokrates.exe compute-witness -i main -a 15 1 50 15 1 50 15 1 50 0 0 0 0 0 0 0 0 0 0 0 0 10 1 75 10 1 75 10 1 75 0 0 0 0 0 0 0 0 0 0 0 0 3
	zokrates.exe generate-proof -i main
	zokrates verify