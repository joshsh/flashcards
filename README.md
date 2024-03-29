**Flashcards** is a feedback mechanism which attempts to optimize rote learning.  It's good for drilling Chinese characters on long Beijing subway rides, among other things.

The premise of the application is that human memory is subject to [exponential decay](http://en.wikipedia.org/wiki/Exponential_decay).  The longer you go without refreshing your memory of a given  symbol, the more it fades, and the greater the risk that you will forget whatever it is it meant to you.  The program grew out my experiences drilling characters with traditional paper flashcards: I found myself constantly organizing the cards into sets to be tried again after one day, two days, four days, and so on exponentially, as this seemed to yield the most information retained per time spent.  Flashcards attempts to automate this process and to minimize the decay of a set of symbols, or cards, you are attempting to learn by taking into account your history of trials at seeing the "front side" of each card and attempting to recall whatever information you have associated with the "back side".  Cards can be made up of any kind of symbols or cues; Flashcards does not specify.

A graphical Flashcards interface is included in [Extendo-Android](https://github.com/joshsh/extendo-android).

### Build (Java)

```java
mvn install
```

### Use


