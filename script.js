const texts = [
"AI Enthusiast",
"Machine Learning Developer",
"MATLAB Programmer",
"Future Software Engineer"
];

let count = 0;
let index = 0;
let currentText = "";
let letter = "";

(function typing(){
    if(count === texts.length){
        count = 0;
    }

    currentText = texts[count];
    letter = currentText.slice(0, ++index);

    document.getElementById("typing").textContent = letter;

    if(letter.length === currentText.length){
        count++;
        index = 0;
        setTimeout(typing, 1500);
    }else{
        setTimeout(typing, 100);
        }
    }
)
();