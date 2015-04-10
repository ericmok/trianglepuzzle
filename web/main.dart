// Copyright (c) 2015, Eric Mok. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:async' as async;

class YodleNumber {
  static const num MAX_VALUE = 10000;
  
  num level = -1;
  num index = -1; 
  num value = -1;
  YodleNumber winningChild = null;
  bool winning = false;
  num _winningChildSum = 0;
  bool _winningLeft = true;

  Function callback = null;
  html.Element element;
  
  YodleNumber(this.value) {
    this.element = createBox();
    this.element.style.background = "rgba(0, 0, 0, ${value / MAX_VALUE})";
  }
  
  set winningLeft(bool val) {
    _winningLeft = val;
    
    if (val) {
      this.element.classes.add("winning-left-child");
    } else {
      this.element.classes.add("winning-right-child");
    }
  }
  set winningRight(bool val) {
    this.winningLeft(!val);
  }
  
  get winningLeft {
    return _winningLeft; 
  }
  get winningRight {
    return !_winningLeft;
  }

  bool operator > (YodleNumber other) {
    return this.value > other.value;
  }
  bool operator == (YodleNumber other) {
    return this.value == other.value;
  }
  bool operator < (YodleNumber other) {
    return this.value < other.value;
  }

  
  set winningChildSum(num val) {
    _winningChildSum = val;
    element.setAttribute("data-winningchildsum", _winningChildSum.toString());
  }
  get winningChildSum {
    return _winningChildSum;
  }
  
  String toString() {
    return this.value.toString();
  }
  
  html.Element createBox() {

    html.DivElement spanElement = new html.DivElement();
    spanElement.append(new html.Text(" "));
    spanElement.classes.add("ynum");
    
    num normalizedColor = 1 - value / MAX_VALUE;
    spanElement.style.background = "rgba(0, 0, 0, 1)";
    
    spanElement.setAttribute("data-value", value.toString());
    
    spanElement.addEventListener("mouseover", (ev) {
      if (this.callback != null) {
        callback(this);
      }
    });
    
    return spanElement;
  }
}

/**
 * A  divide and conquer algorithm run in reverse
 */
YodleNumber calculate(tree, num layer) {
  
  if (layer - 1 < 0) {
    print("Value: ${tree[0][0].value + tree[0][0].winningChildSum}");
    return tree[0][0];
  }
  
  var bottomLayer = tree[layer];
  var topLayer = tree[layer - 1];
  
  for (var i = 0; i < bottomLayer.length - 1; i += 1) {
    var pair = [];
    pair.add( bottomLayer[i].value + bottomLayer[i].winningChildSum );
    pair.add( bottomLayer[i + 1].value + bottomLayer[i + 1].winningChildSum );
    
    topLayer[i].winningLeft = (pair[0] >= pair[1]);
    topLayer[i].winningChild = (pair[0] >= pair[1]) ? bottomLayer[i] : bottomLayer[i + 1];
    
    var max = math.max(pair[0], pair[1]);
    topLayer[i].winningChildSum = max;
  }
  
  return calculate(tree, layer - 1);
}

async.Timer timer = null;

void showPath(YodleNumber yodleNumber) {
  
  if (timer != null) {
    timer.cancel();
  }
  
  timer = new async.Timer(const Duration(milliseconds: 180), () {

    html.querySelectorAll(".show-path").classes.remove("show-path");
    
    YodleNumber current = yodleNumber;
    
    while (current != null) {
      current.element.classes.add("show-path");
      current = current.winningChild;  
    }  
  });
  
}

html.Element createLayer(num index) {
  var divElement = new html.DivElement();
  divElement.classes.add("ylayer");

  return divElement;
}


void main() {
    List<List<YodleNumber>> tree = new List<List<YodleNumber>>();
    
    var url = "/data/triangle.txt";
    html.HttpRequest.getString(url).then((String result) {
      print("result");
      List<String> lines = result.split("\r\n");
      print("Lines: ${lines.length}");
      
      html.Element output = html.document.querySelector("#output");
      output.style.display = "none";
      
      for (var i = 0; i < lines.length; i++) {
        
        html.DivElement divElement = createLayer(i);
        
        lines[i] = lines[i].trim();

        List<String> numbers = lines[i].split(" ");

        tree.add(new List<YodleNumber>());
        
        for (var a = 0; a < numbers.length/2; a += 1) {
          num number = num.parse(numbers[2*a].trim());
          
          YodleNumber currentYodleNumber = new YodleNumber(number);
          currentYodleNumber.level = i;
          currentYodleNumber.index = a;
          
          currentYodleNumber.callback = showPath;
          
          YodleNumber currentNextYodleNumber = null; 
          
          tree[i].add(currentYodleNumber);
          
          num nextNumber;
          if (2*a + 1 < numbers.length) {
            nextNumber = num.parse(numbers[2*a + 1].trim());
            
            currentNextYodleNumber = new YodleNumber(nextNumber);
            tree[i].add(currentNextYodleNumber);
            
            currentNextYodleNumber.level = i;
            currentNextYodleNumber.index = a;
            currentNextYodleNumber.callback = showPath;
          }
          else {
            nextNumber = -1;
          }
          
          divElement.append(currentYodleNumber.element);
          
          if (currentNextYodleNumber != null) {
            divElement.append(currentNextYodleNumber.element);  
          }                    
        }
        
        output.append(divElement);
      }
      
      print("tree");
      print("$tree");
      num maxSum = calculate(tree, tree.length - 1).value + tree[0][0].winningChildSum;
      
      var answer = html.document.querySelector("#answer");
      answer.innerHtml = maxSum.toString();
      
      showPath(tree[0][0]);
      
      output.style.display = "block";
      
      print("done");
    });
}