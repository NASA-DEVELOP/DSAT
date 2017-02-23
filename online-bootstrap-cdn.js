function runcdn(){
var xhr = new XMLHttpRequest();
xhr.open("GET", "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css", false);

xhr.send()
//If CDN connection for Bootstrap is available (i.e, user is online), connect to CDN
if(xhr.status.toString()[0] === 2){
  var a = document.createElement('link');
  a.rel = "stylesheet";
  a.href = "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css";
  a.integrity = "sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u";
  a.crossorigin = "anonymous";
  document.head.appendChild(a);
  console.log("Connection Succesful!");
 }
  else{
    console.log("Connection Unsuccesful!");
  }
}
//Else, proceed with the downloaded Bootstrap file
runcdn();
