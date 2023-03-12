const flattenObject = (obj: Dictionary, prefix: string = ''): Dictionary =>
  Object.keys(obj).reduce((acc: Dictionary, k: string) => {
    const pre: string = prefix.length ? `${prefix}.` : '';
    if (
        typeof obj[k] === 'object' &&
        obj[k] !== null &&
        Object.keys(obj[k]).length > 0
    ) {
        Object.assign(acc, flattenObject(obj[k] as Dictionary, pre + k));
    } else {
        acc[pre + k] = obj[k];
    }
    return acc;
  }, {});

const nestedObj = { a: { b: { c: 1 } }, d: 2 };
console.log(flattenObject(nestedObj));
// { 'a.b.c': 1, d: 2 }
