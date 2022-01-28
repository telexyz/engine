## ArchiText: Interactive Hierarchical Topic Modeling

https://www.youtube.com/watch?v=-r9sox7jk7w

Human-in-the-loop topic modeling allows users to explore and steer the process to produce better quality topics that align with their needs. When integrated into visual analytic systems, many existing automated topic modeling algorithms are given interactive parameters to allow users to tune or adjust them. However, this has limitations when the algorithms cannot be easily adapted to changes, and it is difficult to realize interactivity closely supported by underlying algorithms. Instead, we emphasize the concept of tight integration, which advocates for the need to co-develop interactive algorithms and interactive visual analytic systems in parallel to allow flexibility and scalability. In this paper, we describe design goals for efficiently and effectively executing the concept of tight integration among computation, visualization, and interaction for hierarchical topic modeling of text data. We propose computational base operations for interactive tasks to achieve the design goals. To instantiate our concept, we present ArchiText, a prototype system for interactive hierarchical topic modeling, which offers fast, flexible, and algorithmically valid analysis via tight integration. Utilizing interactive hierarchical topic modeling, our technique lets users generate, explore, and flexibly steer hierarchical topics to discover more informed topics and their document memberships.

![](files/ArchiText.png){width=800 height=500}


https://faculty.cc.gatech.edu/~aendert3/resources/Kim2020ArchiText.pdf


## module 4a/ Tìm topics cho từng đoạn của 150 bài pháp

### INPUT:
  - Khoảng 7500 đoạn văn bản ngắn
  - Init categories dưới dạng cây mà người dùng quan tâm

### OUPUT:
  - Phát hiện thêm các topics (representative terms) để làm rõ hơn nội dung của các init categories

### REPEAT: 
  - Dựa vào kết quả trên, điều chỉnh init categories và lại bắt đầu lại để đạt được cây categories người dùng thấy ưng.

_NOTE_: Phần này ko cần `n-gram`, không cần `syllables2words`
mà cần `dict_matching`, `word2vec` ... Cụ thể như sau:

* Nhóm âm tiết thành từ (dict matching)
* Loại bỏ stopwords (dùng stopword dict)
* Nhúng các cụm từ (1 câu có thể có nhiều matching) vào không gian vectors
* Căn chỉnh vị trí vectors sao cho có độ tương đồng về khoảng cách với các terms trong cây categories
* Clustering để tìm ra thêm các topics (representative terms)

## Libs

https://opensourcelibs.com/libs/topic-modeling

## Hierarchical Topic Mining via Joint Spherical Tree and Text Embedding
  https://github.com/yumeng5/JoSH
  https://yumeng5.github.io/files/JoSH.pdf
  https://arxiv.org/pdf/2007.09536.pdf

### Xem video https://www.youtube.com/watch?v=AIvtHkPiIpo

![](files/hierarchical-topic-modeling.png){width=800 height=320}

![](files/hierarchical-topic-mining.png)

