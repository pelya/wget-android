#!/bin/sh

NCPU=4
ARCH_LIST="armeabi x86 mips"

[ -d openssl ] || {
	git clone git://github.com/fries/android-external-openssl.git openssl/jni || exit 1
	echo APP_MODULES := libcrypto-static libssl-static > openssl/jni/Application.mk
	echo APP_ABI := all >> openssl/jni/Application.mk
	ndk-build -j$NCPU -C openssl || exit 1
	for ARCH in $ARCH_LIST; do
		mkdir -p openssl/$ARCH/lib
		ln -s -f ../jni/include openssl/$ARCH/include
		cp -f openssl/obj/local/$ARCH/libcrypto-static.a openssl/$ARCH/lib/libcrypto.a || exit 1
		cp -f openssl/obj/local/$ARCH/libssl-static.a openssl/$ARCH/lib/libssl.a || exit 1
	done
}

[ -e ../configure ] || {
	D="`pwd`"
	cd ..
	./bootstrap || exit 1
	cd "$D"
}

for ARCH in $ARCH_LIST; do

	case $ARCH in
		x86) TOOLCHAIN=i686-linux-android;;
		mips) TOOLCHAIN=mipsel-linux-android;;
		*) TOOLCHAIN=arm-linux-androideabi;;
	esac

	mkdir -p $ARCH
	cd $ARCH
	[ -e Makefile ] || {
		../setCrossEnvironment-$ARCH.sh ../../configure --host=$TOOLCHAIN --with-ssl=openssl --with-libssl-prefix=`pwd`/../openssl/$ARCH --disable-nls --disable-iri || exit 1
	} || exit 1

	make -j$NCPU || exit 1
	cp -f src/wget .
	../setCrossEnvironment-$ARCH.sh sh -c '$STRIP --strip-unneeded wget' || exit 1
	cd ..

done
