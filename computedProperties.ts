let _close: number;
let _low: number;
let _open: number;
let _timestamp: number;
let _high: number;

class ComputedProperties {

  constructor ({ close, high, low, open, ...args }) {
        
    // Make floats fixed to two points
    Object.defineProperty(this, 'close', {
        set(closeVal) {
            _close = +parseFloat(closeVal).toFixed(2);
        },
        get() {
            return _close;
        }
    });
    
    Object.defineProperty(this, 'high', {
        set(highVal) {
            _high = +parseFloat(highVal).toFixed(2);
        },
        get() {
            return _high;
        }
    }); 
    
    Object.defineProperty(this, 'low', {
        set(lowVal) {
            _low = +parseFloat(lowVal).toFixed(2);
        },
        get() {
            return _low;
        }
    }); 
    
    Object.defineProperty(this, 'open', {
        set(openVal) {
            _open = +parseFloat(openVal).toFixed(2);
        },
        get() {
            return _open;
        }
    });
    
    // Adds milliseconds to exchange timestamp so its correctly recognised by JS
    Object.defineProperty(this, 'timestamp', {
        set(tsVal) {
            _timestamp = parseInt(tsVal) * 1000;
        },
        get() {
            return _timestamp;
        }
    });
    
    this.close = close;
    this.low = low;
    this.open = open;
    this.high = high;
    this.volume = args?.volume;
    this.timestamp = args?.timestamp;
    this.symbol = args?.symbol;
  }
}
