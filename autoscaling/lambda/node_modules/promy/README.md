# promy

Conditional promisify. Transform callback-based function to callback-and-promise-based one.

## Install

```bash
npm install promy
```

## Usage

It works like easy old good promisify, so if you have some async callback-based function you can do something like this:

```js
const promy = require('promy');
const fn = promy(
    require('./someAsyncCallbackBasedFunction')
);
````

Now promisified function can be used in two ways. It can return promise if called with only one first argument, or it can run callback if it given as second argument.

```js
// callback way:

fn(arg, (err, res) => {
    console.log(err ? err : res);
});


//promise way:

fn(arg)
    .then((res) => console.log(res))
    .catch((err) => console.log(err));
```

## License

MIT