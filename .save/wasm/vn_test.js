const IS_NODE_JS = (typeof window === 'undefined');

let _exports, _buffer;

let import_obj = {
  env: {
    logString: (size, index) => {
        let s = "", i = index, n = index + size;
        for (; i < n; ++i) { s += String.fromCharCode(_buffer[i]); }
        console.log(s);
    },
    logStr: (ptr) => {
      let str = "", code;
      for(; code = _buffer[ptr]; ptr++) { 
        str += String.fromCharCode(code); 
      }
      console.log(str);
    },
    printResult: (result) => { 
      console.log(`The result is ${result}`); 
    },
  },
};

async function initWasmAndRun(func) {
  let wasm_binary_array;

  if (IS_NODE_JS) { // node.js

    const fs = require('fs');
    const source = fs.readFileSync("./vn_telex.wasm");
    wasm_binary_array = new Uint8Array(source);

  } else { // browser

    const response = await fetch("./vn_telex.wasm");
    wasm_binary_array = await response.arrayBuffer();

  }

  let results = await WebAssembly.instantiate(
    wasm_binary_array, 
    import_obj
  );

  _exports = results.instance.exports;
  _buffer = new Uint8Array(_exports.memory.buffer);

  func();
}

function fillStrToBuffer(str, index) {
  for (let size = str.length, i = 0; i < size; ++i) {
    _buffer[index + i] = str.charCodeAt(i);
  }  
}

function canBeVietnamese(str, index = 0) {
  fillStrToBuffer(str, index);
  return _exports.wasmCanBeVietnamese(index, str.length, _buffer);
}

function runAndLog(func, str, index = 0) {
  console.log(str, func(str, index));
}



function _getTone(s) {
  if (s.match(/á|ắ|ấ|ó|ớ|ố|ú|ứ|é|ế|í|ý/i)) return 's';
  if (s.match(/à|ằ|ầ|ò|ờ|ồ|ù|ừ|è|ề|ì|ỳ/i)) return 'f';
  if (s.match(/ả|ẳ|ẩ|ỏ|ở|ổ|ủ|ử|ẻ|ể|ỉ|ỷ/i)) return 'r';
  if (s.match(/ã|ẵ|ẫ|õ|ỡ|ỗ|ũ|ữ|ẽ|ễ|ĩ|ỹ/i)) return 'x';
  if (s.match(/ạ|ặ|ậ|ọ|ợ|ộ|ụ|ự|ẹ|ệ|ị|ỵ/i)) return 'j';
  return '';
}

function _removeToneAndUnrollMarks(s) {
  return s.
    replace(/[àáạảã]/g , "a").
    replace(/[âầấậẩẫ]/g, "aa").
    replace(/[ăằắặẳẵ]/g, "aw").
    replace(/[èéẹẻẽ]/g , "e").
    replace(/[êềếệểễ]/g, "ee").
    replace(/[òóọỏõ]/g,  "o").
    replace(/[ôồốộổỗ]/g, "oo").
    replace(/[ơờớợởỡ]/g, "ow").
    replace(/[ùúụủũ]/g,  "u").
    replace(/[ưừứựửữ]/g, "uw").
    replace(/[ìíịỉĩ]/g,  "i").
    replace(/[ỳýỵỷỹ]/g,  "y");
}

function _isVietnamese(str) {
  str = _removeToneAndUnrollMarks(str) + _getTone(str);
  console.log("canBeVietnamese", str);
  return canBeVietnamese(str) === 1 ? true : false;
}

function assertEqual(x, y) {
    if (x !== y) console.log(x, "!==", y);
};

if (IS_NODE_JS) {
  initWasmAndRun(() => {

    runAndLog(canBeVietnamese, "hello");
    runAndLog(canBeVietnamese, "muoons");

    assertEqual(_isVietnamese("của"), true);
    assertEqual(_isVietnamese("huyết"), true);
    assertEqual(_isVietnamese("huyêt"), false);
    assertEqual(_isVietnamese("boong"), true);
    assertEqual(_isVietnamese("niềm"), true);
    assertEqual(_isVietnamese("iềm"), false);
    assertEqual(_isVietnamese("iề"), false);
    assertEqual(_isVietnamese( "yêu"), true);
    assertEqual(_isVietnamese( "yê"), false);
    assertEqual(_isVietnamese("tyêu"), false);
    assertEqual(_isVietnamese("ỉa"), true);
    assertEqual(_isVietnamese("ỉam"), false);

    "gioạ,gióa,giuệ,giuyên,giuyệt,giuy".split(",").forEach(x => {
        assertEqual(_isVietnamese(x), false);
        assertEqual(_isVietnamese(x.replace("gi","d")), true);
    });
  });
}