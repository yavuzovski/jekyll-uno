---
title: rest-graphql-1
date: 2018-06-17 15:31:21
categories: [backend, graphql, rest]
tags: [backend, graphql, rest, nodejs, exressjs, mongodb]
notranslate: true
---

Bu yazıda sizlere GraphQL mimarisini anlatmaya çalışacağım.
Ancak bunu yapabilmek için öncelikle GraphQL'in çözüm olduğu 
sorunları gösterebilmek adına REST mimarisine değinmemiz gerekiyor.
Bu nedenle, yazıyı iki bölüme ayırdım. İlk bölümde ufak bir REST API
oluşturacağız. İkinci bölümde de aynı API'ı GraphQL mimarisi ile 
yaparak REST mimarisinin yetersiz ve eksik kaldığı yerleri ve
GraphQL'in bunları nasıl çözdüğünü göreceğiz. Kullanacağımız teknolojiler:

- NodeJS
- ExpressJS
- MongoDB

# REST API

### Veri Modeli

REST ve GraphQL arasındaki farkı görmemizi sağlayacak çok basit
bir veri modeli oluşturdum. Veri modeli, parça ve şarkıcı koleksiyonlarını
barındırmakta. JSON formatında veri modelimizi temsil edecek olursak:
```
{ 
  "tracks": [
    {
      "_id:": "1",
      "title": "Aç Kapıyı Gir İçeri",
      "genre": "pop",
      "artistId": "1"
    }
    ...
  ],
  "artists": [
    {
      "_id:": "1",
      "name": "Özdemir Erdoğan",
      "age": "78"
    }
    ...
  ]
}
```

### RESTful Yaklaşım
Oluşturacağımız API'ın şu iki koşulu sağlamasını istiyoruz:

1. Parça ve şarkıcı bilgileri üzerinden [CRUD] işlemleri yapabilmek.

    **Çözüm:** CRUD işlemleri için `GET`, `POST`, `PUT`, `PATCH` ve `DELETE` HTTP metotlarını kullanacağız.
    Endpoint'lerimiz şu şekilde olacak:
    - /tracks
    - /tracks/:trackId
    - /artists
    - /artists/:artistId
   
2. İstemci tarafında parça adı, parça türü ve o parçanın şarkıcısının adını tek bir JSON objesinde elde etmek.
Temsil edecek olursak:
    ```
    {
      "title": "Aç Kapıyı Gir İçeri",
      "genre": "pop",
      "artist": {
        "name": "Özdemir Erdoğan"
      }
    }
    ```
    **Çözüm:** Bu koşulu yerine getirmek için istemci tarafında seçebileceğimiz bir çözüm, sunucu tarafında
    seçebileceğimiz iki çözüm var. Buraya CRUD kısmını bitirdikten sonra tekrar geleceğiz.

### Uygulama

Şimdi modellerimizi yazılıma dökebiliriz. Öncelikle yeni bir klasör açıp
yeni bir NodeJS projesi başlatalım.

```
mkdir rest-example && cd rest-example
npm init -y
```

İlk önce yapmamız gereken basit bir HTTP sunucusu oluşturmak. Bunun için
ExpressJS kullanacağız. ExpressJS paketini projemize ekleyelim ve 
`server.js` adında yeni bir dosya oluşturalım.

```
npm i --save express
touch server.js
```

[CRUD]: https://en.wikipedi0.org/wiki/Create,_read,_update_and_delete
