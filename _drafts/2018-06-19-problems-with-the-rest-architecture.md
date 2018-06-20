---
title: problems-with-the-rest
date: 2018-06-19 17:00:12
categories: [backend, graphql, rest]
tags: [backend, graphql, rest]
---

Bu yazıda sizlere REST mimarisindeki problemleri göstermeye çalışacağım.
Ardından bu yazının devamı niteliğinde olacak ikinci bir yazıda, bu problemlere
çözüm olan GraphQL mimarisini anlatacağım. Ayrıca GraphQL mimarisi ile
CRUD işlemleri yapabileceğimiz basit bir NodeJS uygulaması oluşturacağım.

### Giriş

Aslında bu yazıda direk olarak GraphQL'yi anlatmayı amaçlamıştım ancak GraphQL'nin REST'deki
hangi problemlere çözüm olduğunu gösterebilmek için yazdıklarım çok uzadı
ve ayrı bir post olarak yayınlamaya karar verdim. REST hakkında tanım yapmayacağım, internette
zaten bunun hakkında bir çok yazı mevcut. Örnek bir uygulama üzerinde, bir front-end
developer'in gözünden REST mimarisinin eksik olduğu kısımları göstermeye çalışacağım.

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
- [/users/:userId]
``` json
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
}
```

Response'lerin tamamını görmek için linklere gidebilirsiniz.

### RESTful Yaklaşımlar ve Problemleri

Ana sayfada post'ları istediğimiz şekilde görüntüleyebilmek için
yapmamız gerekenler şunlar: Öncelikle `/posts` endpoint'inden post'ları
almak. 
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
Ardından her bir post için `userId` değerini kullanarak `/users/:userId` endpoint'inden 
user'leri almak. Yani ilk post için [/users/1] endpoint'inden elde edeceğimiz sonuç:
``` json
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
}
```
Bütün post'lar için user'leri aldıktan sonra ihtiyacımız olan bütün verileri
elde etmiş oluyoruz. Post'ların `title` ve `body` değerleriyle `user`'lerin
`username` değerini birleştirerek elde etmek istediğimiz yapıyı kurmuş oluyoruz.
Yani elde etmek istediğimiz sonuç şu şekilde olacak:

``` json
[
  {
    "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
    "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto",
    "user": {
      "username": "Bret"
     }
  },
  ...
]
```

Bu REST yaklaşımında, GraphQL'nin çözmüş olduğu iki büyük problem
var. İlki [over-fetching] problemi. Yani response'ler içerisinde
bize ihtiyacımız olmayan verilerin de geri dönüyor olması. `/users/:userId`
endpoint'inden bizim aslında sadece `username` değerine ihtiyacımız var
ancak bize dönen response'de `username` dışında başka bir sürü değer de
dönmekte. Dönen değerlere tekrar bakalım.
``` json
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
}
```

Diğer problem ise [under-fetching] problemi. Yani ihtiyacımız olan
veriyi elde edebilmek için başka bir endpoint'e daha gitmemiz
gerekmesi. Bu örneğimizde, post'lara ulaşmak için `1` kere `/posts` endpoint'ine request yolladık.
Ardından elde ettiğimiz `n` tane post değeri için de `n` kere `/users/:userId` endpoint'ine request yollamamız
gerekti. Bu problem `n + 1` problemi olarak da bilinmekte. Eğer ihtiyacımız olan
veri yapısı çok daha iç içe bir yapıya sahip olsaydı, en kötü senaryoda, her bir derinlik için `n` in kuvveti kadar request 
yollamamız gerekebilirdi. Bu da ciddi miktarda gereksiz HTTP trafiğine sebep olabilir.

### Problemleri Yine REST İle Çözmeye Çalışmak

Peki bu problemleri RESTful yaklaşımla da çözemez miyiz? Çözebiliriz ancak
bu çözümler de beraberlerinde başka problemleri getiriyor. Bu çözümlerden bazıları:

1. Mevcut endpoint'lerin response değerlerini düzenlemek.

   - Mesela over-fetching problemini engellemek için back-end developer'den `/users/:userId` endpoint'ini
    sadece `username` değerini döndürecek şekilde düzenlemesini isteyelim.
      ``` json
      {
        "username": "Bret"
      }
      ```
    Bu çözümle ihtiyacımız olmayan verilerden kurtulmuş olduk. Uygulama fikrimize geri dönelim.
    Aradan biraz zaman geçti ve ana sayfada bir değişiklik oldu. Artık post'ların altında `username` değeri
    yerine `email` değerinin görüntülenmesini istiyoruz ancak `/users/:userId` endpoint'inde `email` değeri yok!
    `email` değerine ulaşabilmek için tekrar back-end developer'in kapısını çalmak zorundayız.

    - Under-fetching problemini çözmek için de back-end developer'den `/posts` endpoint'ini, `userId` yerine
    o id'e sahip olan user'in `username` değerini döndürecek şekilde düzenlemesini isteyelim.
    Yani `/posts` endpoint'inden tam olarak ihtiyacımız olan yapı dönecek.
      ``` json
      [
        {
          "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
          "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto",
          "user": {
            "username": "Bret"
          }
        },
        ...
      ]
      ```
    Bu sayede sadece `/posts` endpoint'ine tek bir request
    yaparak `username` değerlerini de elde etmiş olacağız ve `n + 1` yerine `1` request yaparak under-fetching problemi
    de çözülmüş olacak. Aslında bu çözüm over-fetching problemini de çözmekte. Ancak bu çözümün de beraberinde
    getirebileceği problemler var.

      Uygulama fikrimize geri dönelim. Yeni bir değişiklik daha oldu ve artık
      ana sayfada en çok hangi şehirlerden post atıldığını göstermek istiyoruz. Bu istatistiği elde etmek için de
      eski endpoint'lere göre izlememiz gereken yol şu şekilde: 
      `/posts` endpoint'inden post'ları elde etmek. Ardından her bir post için `userId` değerini kullanarak `/users/:userId`
      endpoint'inden `city` değerini almak.
      Ancak artık `/posts` endpoint'inden `userId` yerine yalnızca `username` değeri dönmekte! Bunun için
      ya `/posts` endpoint'ini back-end developer'den şehir bilgilerini de döndürecek şekilde tekrar düzenlemesini,
      ``` json
      [
        {
          "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
          "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto",
          "user": {
            "username": "Bret",
            "address": {
              "city": "Gwenborough" 
            }
          }
        },
        ...
      ]
      ```
      ya da `userId` değerini geri koymasını istemeliyiz.
      ``` json
      [
        {
          "userId": 1,
          "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
          "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto",
          "user": {
            "username": "Bret"
          }
        },
        ...
      ]
      ```


2. İhtiyaca göre yeni endpoint'ler oluşturmak.

    - Ana sayfada post'ları listeleme örneğimize geri dönelim. `/posts` ve `/users/:userId` endpoint'lerinde
    değişiklikler yapmak yerine, back-end developer'den yeni bir endpoint oluşturmasını isteyebiliriz. Mesela
    back-end developer bize şöyle bir endpoint oluştursun: `/posts/usernames`. Bu endpoint'den dönen response de şu şekilde
    olsun:
      ``` json
      [
        {
          "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
          "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto",
          "user": {
            "username": "Bret"
          }
        },
        ...
      ]
      ```
    Yani direk olarak elde etmek istediğimiz sonuç. Bu çözümle hem `/posts` veya `/users/:userId` endpoint'lerine gereksinim
    duyabilecek diğer bileşenleri bozmamış olduk, hem de over-fetching ve under-fetching problemlerini çözmüş olduk.

      Peki bu çözümdeki problem nedir? Buradaki problem, aslında çözümün kendisi. Yani yeni bir endpoint oluşturmak.
      Yeni bir endpoint demek, back-end tarafında takip edilmesi gereken yeni kodlar demek.

3. Endpoint'lere `query string` halinde argümanlar verip response değerlerini tarif edebilmek.

   - Tekrar ana sayfada post'ları listeleme örneğine ve endpoint'lerimizin ilk hallerine geri dönecek olursak, back-end'de
   `/posts` endpoint'ini `fields` adında bir argüman alacak şekilde değiştirilmesini isteyebiliriz. Ayrıca bu argümanlar
   opsiyonel olabilir ve eğer bu argümanlar verilmemişse endpoint eski halindeki gibi çalışabilir. Yani yeni endpoint'imiz
   ve dönen response şu şekilde olsun:

      `/posts?fields=title,body,username`
     ``` json
     [
       {
         "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
         "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto",
         "user": {
           "username": "Bret"
         }
       },
       ...
     ]
     ```
      `/posts`
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
  Peki bu yaklaşımda karşılaşabileceğimiz problemler neler? Yeni bir endpoint oluşturmanın getirdiği problemler ile aynı problemler.
  Ancak burada ayrıyetten query string'leri kontrol etmek için daha kompleks kodlar yazılması gerekecek.

### Sonuç

Gördüğümüz üzere RESTful yaklaşımlar ile over-fetching ve under-fetching'in önüne geçmek mümkün.
Ancak bütün bu çözümler, **front-end'de doğan ihtiyaçlar doğrultusunda
back-end tarafında, back-end developer'in statik olarak kod yazmasını gerektiren** çözümler.
**Aslında ihtiyacımız olan bütün veriye sahibiz, ancak bu verilerden türetmemiz gereken yeni bir
veri yapısı olduğunda, bu yapıyı dinamik bir şekilde oluşturabilecek bir sistem yok.** Bu nedenle, 
türetilen veri yapılarını ya eldeki kaynaklarla over-fetching ve under-fetching'e göz yumarak oluşturacağız ya da 
back-end developer'ler, ihtiyacımız oldukça bize statik olarak çözüm üretecekler. Bu da çoğu zaman front-end ve
back-end'in birbirlerinden bağımsız bir şekilde çalışabilmelerini engellediği için esnek olmayan ve verimsiz bir çözüm.
RESTful yaklaşımla muhtemelen uygulayabileceğimiz en mantıklı çözüm, 
yukarıdaki çözümler arasında dengeyi sağlamak olacaktır. Spesifik veri yapıları için
yeni endpoint'ler oluşturmak, daha az spesifik olanları için diğer endpoint'lere query string'ler
ile argüman verebilmek ve genel veri yapıları için bir miktar over-fetching ve under-fetching'e göz yummak.

İkinci bölümde GraphQL'nin bahsettiğimiz sorunları nasıl çözdüğünü anlatmaya çalıştım.

[JSONPlaceholder]: https://jsonplaceholder.typicode.com/
[/posts]: https://jsonplaceholder.typicode.com/posts
[/users/:userId]: https://jsonplaceholder.typicode.com/users/1
[/users/1]: https://jsonplaceholder.typicode.com/users/1 
[over-fetching]: https://stackoverflow.com/a/44568365
[under-fetching]: https://stackoverflow.com/a/44568365
[İkinci bölümde]: https://yavuzovski.github.io

