const getUniqueElements = (a1, a2) => {
  if (a2.length > a1.length) {
    return a2.filter(ele => !a1.includes(ele));
  } else {
    return a1.filter(ele => !a2.includes(ele));
  }
}

let array1 = ['a', 'b', 'c', 'd'];
let array2 = ['a', 'b', 'c', 'd', 'e', 'f'];

console.log(getUniqueElements(array1, array2));
