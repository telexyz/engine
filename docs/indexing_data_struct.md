[ QUESTION ] Which technique to use? Bloom Filter? Inverted Index? ...
[ ANSWER ] Use Bloom Filter for FTS is a hack. Inverted Index is the way!

https://healeycodes.com/webassembly-search-tools-for-static-websites/

The full-text search engine is powered in part with code from Artem Krylysov’s blog post Let’s build a Full-Text Search engine.

The core data-structure is an inverted index. It maps words to document IDs. This means we can check very quickly (i.e. 100µs within Wasm) which documents a word can be found in. At build time, we loop over the document files and add to the inverted index. We also create a list of results so we can relate a document ID to a document’s metadata (defined in the configuration file). The metadata includes the title and URL so that we can display a list of search results in the browser.

We can return results for multiple keywords by looking at the common document IDs for each keyword. This takes linear time as the IDs are inserted into the index in order.

The document "Alice likes to go fishing" becomes ["alice", "go", "fish"]. The search term "Fishing" is also turned into a token, at search-time it becomes "fish".

https://artem.krylysov.com/blog/2020/07/28/lets-build-a-full-text-search-engine/

```js
documents = {
    1: "a donut on a glass plate",
    2: "only the donut",
    3: "listen to the plate machine",
}

index = {
    "a": [1],
    "donut": [1, 2],
    "on": [1],
    "glass": [1],
    "plate": [1, 3],
    "only": [2],
    "the": [2, 3],
    "listen": [3],
    "to": [3],
    "machine": [3],
}

> search("donut plate")
[[1, 2], [1, 3]]

> andQuery()
[1]

> orQuery()
[1,2,3]
```
