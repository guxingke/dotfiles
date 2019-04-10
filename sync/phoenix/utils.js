function alert(message) {
    var modal = new Modal();
    modal.message = message;
    modal.duration = 1;
    modal.show();
 }
 
 function log(obj) {
    Phoenix.log(JSON.stringify(obj))
 }
 
 function assert(condition, message) {
    if (!condition) {
       throw message || "Assertion failed";
    }
 }