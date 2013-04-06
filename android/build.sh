#!/bin/sh

NCPU=4

[ -d openssl ] || {
	git clone git://github.com/fries/android-external-openssl.git openssl/jni || exit 1
	echo APP_MODULES := libcrypto-static libssl-static > openssl/jni/Application.mk
	echo APP_ABI := armeabi >> openssl/jni/Application.mk
	ndk-build -j$NCPU -C openssl || exit 1
	mkdir -p openssl/jni/lib
	cp -f openssl/obj/local/armeabi/libcrypto-static.a openssl/jni/lib/libcrypto.a || exit 1
	cp -f openssl/obj/local/armeabi/libssl-static.a openssl/jni/lib/libssl.a || exit 1
}

[ -e ../configure ] || {
	D="`pwd`"
	cd ..
	./bootstrap || exit 1
	cd "$D"
}

[ -e Makefile ] || {
	#CFLAGS="-Iopenssl/jni/include" \
	#LIBS="-Lopenssl/obj/local/armeabi" \
	env BUILD_EXECUTABLE=1 ./setCrossEnvironment.sh ../configure --host=arm-linux-androideabi --with-ssl=openssl --with-libssl-prefix=`pwd`/openssl/jni --disable-nls --disable-iri || exit 1
}

make -j$NCPU || exit 1
cp -f src/wget .
./setCrossEnvironment.sh sh -c '$STRIP --strip-unneeded wget' || exit 1
