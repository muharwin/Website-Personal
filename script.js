const texts = [
    "AI Enthusiast",
    "Machine Learning Developer",
    "MATLAB Programmer",
    "Informatics Engineering Student"
];

let count = 0;
let index = 0;
let currentText = "";
let letter = "";
let isDeleting = false;

(function typing() {
    if (count === texts.length) {
        count = 0;
    }
    currentText = texts[count];

    if (isDeleting) {
        // Logika saat menghapus teks
        letter = currentText.slice(0, --index);
    } else {
        // Logika saat mengetik teks
        letter = currentText.slice(0, ++index);
    }

    document.getElementById("typing").textContent = letter;

    let typeSpeed = 100; // Kecepatan mengetik dasar

    if (isDeleting) {
        typeSpeed /= 2; // Menghapus teks 2x lebih cepat
    }

    // Jika teks selesai diketik penuh
    if (!isDeleting && letter.length === currentText.length) {
        typeSpeed = 2000; // Berhenti sebentar selama 2 detik di teks penuh
        isDeleting = true;
    } 
    // Jika teks selesai dihapus total
    else if (isDeleting && letter.length === 0) {
        isDeleting = false;
        count++;
        typeSpeed = 500; // Jeda sebelum mulai mengetik teks baru
    }

    setTimeout(typing, typeSpeed);
})();
