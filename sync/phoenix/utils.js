 function log(obj) {
    Phoenix.log(JSON.stringify(obj))
 }
 
 function assert(condition, message) {
    if (!condition) {
       throw message || "Assertion failed";
    }
 }
