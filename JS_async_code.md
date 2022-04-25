# JavaScript Notes On Asynchronous Code
* If a function awaits another function, it must be declared as an async function
```
async function awaitsAfunction() {
  let val = await aFunction();
  return val;
}

// Anonymous functions style
const awaitsAFunction = async => aFunction();
```

* a JS promise follows this syntax
```
new Promise((successCallBack, failureCallBack) => {
  // Determine if some action succeeded or failed
  if (error) {
    failureCallBack(error);
  }
  successCallBack(result);
});

```
* To turn an old style callback syntax into promise syntax, use similar to below
```
const query = (con, sql) => new Promise((resolve, reject) => {
    // Function that uses callback syntax wrapped in a promise
    con.query(sql, (error, results) => {
        if (error) {
            reject(error) 
        } else {
            resolve(results)
        }
    });
});
```

* If a function returns a Promise and you don't want to use the older <code>.then</code> syntax you can use the await syntactic sugar
```
let value = await returnsAPromise();
```
