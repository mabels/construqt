var paths = document.getElementsByTagName("path");
for (var i = 0; i < paths.length; ++i) {
  paths[i].style["stroke-width"] = "4px";
  paths[i].style["stroke-dasharray"] = "initial";
}
document.addEventListener("click", function(e) {
  var target = e.target
  console.log(target+":"+target.style["stroke-width"]);
  if (target.tagName != "path") {
    return;
  }
  if (parseInt(target.style["stroke-width"])==8) {
    return;
  }
  var old_width = target.style["stroke-width"];
  target.style["stroke-width"]="8px";
  setTimeout(function() {
    target.style["stroke-width"]=old_width;
  }, 1000)
});
