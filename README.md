# GeoServer Docker Image with GDAL ECW Support

Bu Docker projesi, orjinal geoserver docker imajında olmayan,  GDAL ECW desteği ile özelleştirilmiş bir GeoServer imajı oluşturmayı amaçlar. GeoServer'ın GDAL ile ECW formatını desteklemesi için gereken tüm bağımlılıkları içerir. Ayrıca oracle plugin de yüklenmiştir.

## Kurulum

1. Docker yüklü olmalıdır. (ihtiyaca göre docker-compose yüklü olmalıdır.)
2. Bu projeyi klonlayın:

    ```bash
    git clone https://github.com/<kullanıcı_adı>/<repo_adi>.git
    ```

3. Dockerfile'ı kullanarak imajı oluşturun:

    ```bash
    docker build -t geoserver-gdal-ecw:<sürüm_etiketi> .
    ```

## Kullanım

GeoServer'ı çalıştırmak için aşağıdaki komutu kullanabilirsiniz:

```bash
docker run --name=geoserver-with-ecw --volume='C:\gitprojects\DOCKER-GEOSERVER-WITH-ECW\additional_libs:/opt/additional_libs:rw,Z' --volume='C:\gitprojects\DOCKER-GEOSERVER-WITH-ECW\geoserver_data:/opt/geoserver_data:rw,Z' -p 8080:8080 geoserver-gdal-ecw:<sürüm_etiketi>
```

veya 
GeoServer'ı çalıştırmak için, ihtiyaca göre docker-compose.yml dosyası düzenlendikten sonra aşağıdaki komutu kullanabilirsiniz.

```bash
docker-compose -f docker-compose.yml up -d
```