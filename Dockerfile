# parametre verilen GEOSERVER_VERSION # değerini al
ARG GEOSERVER_VERSION=2.25.x

FROM docker.osgeo.org/geoserver:${GEOSERVER_VERSION}

# ENV CORS_ENABLED=true
# ENV CORS_ALLOWED_METHODS=GET,POST,PUT,HEAD,OPTIONS

ENV INSTALL_EXTENSIONS true
ENV STABLE_EXTENSIONS=gdal,oracle,importer
ENV EXTRA_JAVA_OPTS="-Xms1G -Xmx2G" 
# Geoserver orjinal docker base imaj sec

# tmp dizini için yetki gerekli
RUN chmod 777 /tmp

# mevcutta yuklu gelen gdal-bin ve gdal-data kutuphaneleri
# derlenecek gdal ile karismamasi icin sil
RUN apt-get remove -y gdal-bin gdal-data

# GDAL-3.8.3'un ECW SDK ile birlikte 
# cmake komutuyla derlenebilmesi icin
# gerekli kutuphaneleri yukle
RUN apt-get update && \
    apt-get install -y \ 
    ant \
    unzip \
    build-essential \
    cmake \
    gcc \
    g++ \
    libproj-dev \
    swig \
    python3.10 \
    python3.10-dev \
    python3-pip \
    libsqlite3-dev \
    libexpat1-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libtiff-dev \
    libgeotiff-dev \
    libpng-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Erdas SDK direk wget ile dinamik olarak indirilemiyor
# daha onceden linux'e indirilen .bin dosyasinden
# derleme icin gerekli SDK DESKTOP_Read-Only olarak .zip yapildi  
# ERDAS-ECW_JPEG_2000_SDK-5.5.0.zip olarak ./staticfiles klasundedir

# ECW SDK'nin cikartilacagi klasor dizinini tanimla
ARG ERDAS_ECW_SDK_EXTRACT_PATH=/usr/local/ERDAS_ECW_SDK

# Yerelde saklanan ECW SDK'yi zipten cikart ve .zip dosyasini sil
COPY ./staticfiles/ERDAS-ECW_JPEG_2000_SDK-5.5.0.zip /tmp/
COPY ./staticfiles/ERDAS-ECW_JPEG_2000_SDK-5.5.0.z01 /tmp/
COPY ./staticfiles/ERDAS-ECW_JPEG_2000_SDK-5.5.0.z02 /tmp/
COPY ./staticfiles/ERDAS-ECW_JPEG_2000_SDK-5.5.0.z03 /tmp/
RUN unzip -q /tmp/ERDAS-ECW_JPEG_2000_SDK-5.5.0.zip -d ${ERDAS_ECW_SDK_EXTRACT_PATH}/ && rm /tmp/ERDAS-ECW_JPEG_2000_SDK-5.5.0.zip

# Yerelde saklanan GDAL kaynak kodunu tar.gz'den cikart (gdal-3.8.3 klasörü olusur) ve .tar.gz dosyasini sil
COPY ./staticfiles/gdal-3.8.3.tar.gz /tmp/
RUN tar -xzf /tmp/gdal-3.8.3.tar.gz -C /usr/local/ && rm /tmp/gdal-3.8.3.tar.gz

# derleme icin 'build' adinda bir klasor olustur
WORKDIR /usr/local/gdal-3.8.3
RUN mkdir build 

# derlemek icin build dizinine gec
WORKDIR /usr/local/gdal-3.8.3/build

# GDAL 3.5 ve sonrasi icin derleme cmake ile yapilmaktadir
# Release   modda derleme icin SDK icerisinde 'release' klasoru altindaki libNCSEcw.so.5.5.0.so dosyasi secilmeli
# Debug     modda derleme icin SDK icerisinde 'debug'   klasoru altindaki libNCSEcwd.so.5.5.0.so dosyasi secilmeli
ARG CMAKE_BUILD_TYPE=Release
ARG CMAKE_BUILD_TYPE_DIRNAME=release

# ECW SDK 5.5 icin ortam parametreleri 
ARG ECW_ROOT=${ERDAS_ECW_SDK_EXTRACT_PATH}/Desktop_Read-Only
ARG ECW_INCLUDE_DIR=${ECW_ROOT}/include
ARG ECW_LIBRARY=${ECW_ROOT}/lib/x64/${CMAKE_BUILD_TYPE_DIRNAME}/libNCSEcw.so.5.5.0
ARG GDAL_USE_ECW=ON
ARG GDAL_ENABLE_DRIVER_ECW=ON

# Copy libNCSEcw* files into user libraries 
RUN cp ${ERDAS_ECW_SDK_EXTRACT_PATH}/Desktop_Read-Only/lib/x64/${CMAKE_BUILD_TYPE_DIRNAME}/libNCSEcw* /usr/local/lib/

# Only CMake for GDAL versions >= 3.5.0. (Read: https://gdal.org/development/building_from_source.html)
RUN cmake .. && cmake --build . -- -j$(nproc) && cmake --build . --target install 

# GEOSERVER'ın Gozat Dugmesine Basildiginda gorecegimiz DATA klasorunu degistirilmek istenirse 
# asagidaki ortam parametresi ile ayarlanabilir
# ENV GEOSERVER_DATA_DIR=/opt/geoserver_data/

#gdalinfo --format ECW komutunun calistigini gormek icin
RUN cp /usr/local/gdal-3.8.3/build/*.so /usr/lib && ldconfig /usr/lib

# GDAL derlenirken 'Java Binding' lerin de derlenmesi için
# JRE ve JDK yüklenmiş ve PATH lerde tanımlı olmalı ve ayrıca ant kütüphanesi yüklü olmalı 
# varsayılan olarak cmake komutunda BUILD_JAVA_BINDINGS=ON değerinde olduğundan
# build klasörü altındaki swig klasöründe BUILD_JAVA_BINDINGS libgdalalljni.so dosyamız oluştu.
# GEOSERVER'ın aşağıdaki hatayı almasını önlemek için gerekli .so dosyası java.library.path'te olmalı:
# Native library load failed.
# java.lang.UnsatisfiedLinkError: no gdalalljni in java.library.path:
# .so dosyalarının için java.library.path LINUX işletim sisteminde LD_LIBRARY_PATH ortam parametresi 
# LD_LIBRARY_PATH dizinleri
# LD_LIBRARY_PATH=/usr/java/packages/lib:/usr/lib/x86_64-linux-gnu/jni:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/jni:/lib:/usr/lib
RUN cp /usr/local/gdal-3.8.3/build/swig/java/*.so /usr/lib   

# Eger Docker Image "gdal" extension yuklemeyi desteklemiyorsa asagidaki sekilde yuklenebilir.
# COPY ./staticfiles/geoserver-2.24.1-gdal-plugin.zip /tmp/
# RUN unzip -qo /tmp/geoserver-2.24.1-gdal-plugin.zip -d /tmp
# RUN unzip -qo /tmp/geoserver-2.24.1-gdal-plugin.zip -d ${GEOSERVER_LIB_DIR}/ && rm /tmp/geoserver-2.24.1-gdal-plugin.zip



