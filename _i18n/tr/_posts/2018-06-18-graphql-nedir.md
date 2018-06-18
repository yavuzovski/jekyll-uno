---
title: GraphQL Nedir
date: 2018-06-18 12:00:12
categories: [backend, graphql, rest]
tags: [backend, graphql, rest, nodejs, exressjs]
notranslate: true
---

Bu yazıda sizlere GraphQL mimarisini anlatmaya çalışacağım.
GraphQL'yi tanımladıktan sonra ayrıca NodeJS ve
GraphQL kullanarak basit bir API oluşturacağım.

### Tanım

GraphQL, basitçe tanımlayacak olursak; **client'in, server'dan 
istediği veriyi, yapısını tarif ederek isteyebilmesini sağlayan 
bir sorgulama dilidir.**
Peki neden böyle bir şey yapmak isteyelim? Bunu bir front-end 
developer'in gözünden, uygulama üzerinde 
REST mimarisi ile kıyaslayarak anlatmak çok daha anlaşılır 
olacaktır.

### Örnek Bir Uygulama

Örnek uygulamamız için [JSONPlaceholder] REST API'sini kullanacağız.
Bir blog sitemiz olduğunu düşünelim. Bu blog sitesinin ana sayfasında
blog post'larını ve bu post'ları kimin gönderdiğini görüntülemek istiyoruz.

JSONPlaceholder API'sini kullanarak bu örneği gerçekleştirmek için
ihtiyacımız olan endpoint'ler ve aldığımız response örnekleri şunlar:

- [/posts]
``` json
[
    {
      "userId": 1,
      "id": 1,
      "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
      "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
    },
    ...
]
```
- [/posts/:postId/comments]
``` json
[
    {
      "postId": 1,
      "id": 1,
      "name": "id labore ex et quam laborum",
      "email": "Eliseo@gardner.biz",
      "body": "laudantium enim quasi est quidem magnam voluptate ipsam eos\ntempora quo necessitatibus\ndolor quam autem quasi\nreiciendis et nam sapiente accusantium"
    },
    ...
]
```
- [/users]
``` json
[
    {
      "id": 1,
      "name": "Leanne Graham",
      "username": "Bret",
      "email": "Sincere@april.biz",
      "address": {
        "street": "Kulas Light",
        "suite": "Apt. 556",
        "city": "Gwenborough",
        "zipcode": "92998-3874",
        "geo": {
          "lat": "-37.3159",
          "lng": "81.1496"
        }
      },
      "phone": "1-770-736-8031 x56442",
      "website": "hildegard.org",
      "company": {
        "name": "Romaguera-Crona",
        "catchPhrase": "Multi-layered client-server neural-net",
        "bs": "harness real-time e-markets"
      }
    },
    ...
]
```

Tüm response'leri görmek için linklere gidebilirsiniz.

### RESTful Yaklaşımlar ve Problemleri

Ana sayfa için öncelikle yapmamız gereken `/posts` endpoint'inden post'ları
alıp her bir post için `title` ve `body` değerleriyle beraber `userId` değerini de
kullanarak `/users/:userId` endpoint'inden elde edeceğimiz `username` değerini birleştirmek
ve görüntülemek.

Bu REST yaklaşımında, GraphQL'nin çözmüş olduğu iki büyük problem
var. İlki [over-fetching] problemi. Yani response'ler içerisinde
bize ihtiyacımız olmayan verilerin de geri dönüyor olması. `/users`
endpoint'inden bizim aslında sadece `username` değerine ihtiyacımız var
ancak bize dönen response'de `username` dışında başka bir sürü değer de
dönmekte. Bu da kaynakların boşa tüketilmesine sebep oluyor.

Diğer problem ise [under-fetching] problemi. Yani ihtiyacımız olan
veriyi elde edebilmek için başka bir endpoint'e daha gitmemiz
gerekmesi. `/posts` endpoint'i `username` değerini içermediği için 
her bir post için ayrıca `/users/:userId` endpoint'ine request yollamamız gerekti.
Bu da birden fazla HTTP request'i yollamamıza sebep
olduğundan yine kaynakların boşa tüketilmesine sebep oluyor.

### Problemleri Yine REST İle Çözmeye Çalışmak

Peki bu problemleri RESTful yaklaşımla da çözemez miyiz? Çözebiliriz ancak
bu çözümler de beraberlerinde başka problemleri getiriyor. Mesela
mevcut endpoint'lerin response değerlerini düzenlemek veya ihtiyaca göre 
yeni endpoint'ler oluşturmak bu problemleri RESTful yaklaşımıyla da çözmemizi sağlıyor.
Ancak bu çözümlerin maliyeti de front-end ve back-end developer'lerinin birbirlerinden
bağımsız bir şekilde çalışabilmelerini engellemek. 

Mesela over-fetching problemini engellemek için `/users` endpoint'ini
sadece `username` değerini döndürecek şekilde düzenlediğimizi düşünelim.
Uygulama fikrimize geri dönecek olursak,
ana sayfada bir değişiklik oldu ve artık post'ların altında `username` yerine `name` değerinin 
görüntülenmesini istiyoruz. Bunun için `/users` endpoint'inin back-end developer
tarafından tekrar düzenlenmesini beklemek zorundayız.

Peki bu duruma özel bir endpoint oluşturursak ne olur? Muhtemelen bu durum için en mantıklı
çözüm bu olacaktır. Çünkü bu çözümle hem over-fetching hem de under-fetching 
problemleri çözülebilir. Ancak bu da yine back-end'de bu endpoint'in oluşturulmasını
beklememize sebep olacak. Ayrıca endpoint'ler arttıkça maintain etmemiz gereken şeyler de artacak.

RESTful yaklaşımla muhtemelen uygulayabileceğimiz en mantıklı çözüm, 
yukarıdaki çözümler arasında dengeyi sağlamak olacaktır.
Spesifik veriler için yeni endpoint'ler oluşturmak ancak daha genel veriler için oluşturduğumuz
endpoint'lerimizde bir miktar over-fetching ve under-fetching'e göz yummak.

### Çare GraphQL

Peki GraphQL bu problemları nasıl çözüyor? İstemci tarafında sorgular 
yazmak işte burada devreye giriyor. Sunucudan
dönecek olan verinin yapısı client tarafında sorgularla
belirlendiği için gereksiz veriler dönmüyor. Bu sayede over-fetching
problemi çözülüyor. Ayrıca veri yapısı sorgularla oluşturulabildiğinden
farklı veri yapıları için farklı endpoint'ler oluşturmaya gerek kalmıyor. Bu
sayede de bütün request'ler tek bir endpoint üzerinden yapılıyor ve
under-fetching problemi de çözülmüş oluyor. Yani front-end developer'ın
elinde istediği yapıda veriler alabileceği tek bir endpoint oluyor.
Yeni bir yapı kurmak istediğinde back-end developer ile işi olmuyor,
yalnızca yeni bir sorgu yazması gerekiyor.

Bahsettiğimiz blog sitesinin ana sayfasında post'ları listeleyebilmek için
GraphQL'de şöyle bir sorgu kullanmamız yetecekti.
```
{
  posts {
    title
    body
    user {
      username
    }
}    
```
Syntax'ı gördüğünüz üzere çok basit. Yalnızca key'leri olan bir obje
gibi düşünebilirsiniz.



[CRUD]: https://en.wikipedi0.org/wiki/Create,_read,_update_and_delete
[JSONPlaceholder]: https://jsonplaceholder.typicode.com/
[/posts]: https://jsonplaceholder.typicode.com/posts
[/posts/:postId/comments]: https://jsonplaceholder.typicode.com/posts/1/comments
[/users]: https://jsonplaceholder.typicode.com/users
[over-fetching]: https://stackoverflow.com/a/44568365
[under-fetching]: https://stackoverflow.com/a/44568365