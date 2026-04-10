---
theme: default
title: AI-Assisted Decision Support System
info: |
  Presentasi proposal AI-Assisted DSS dengan layout template UGM.
transition: fade-out
mdc: true
layout: ugm-cover
---

<div class="cover-content">
  <div class="cover-kicker">Project Proposal</div>
  <h1>AI-Assisted Decision Support System</h1>
  <h2 class="cover-subtitle-title">Menyederhanakan pengambilan keputusan melalui antarmuka percakapan dan perhitungan DSS yang terstruktur</h2>
  <div class="cover-divider"></div>
  <p class="cover-desc">
    Sistem ini memandu pengguna menyusun kriteria, bobot, alternatif, dan penilaian melalui chat, lalu menghitung ranking dengan metode DSS yang umum dipakai.
  </p>
  <div class="cover-meta">
    <div>Prima Adi</div>
    <div>Ade Dwi Prayitno</div>
    <div>Flutter, Firebase, DeepSeek API</div>
    <div>Metode: SAW, WP, AHP, TOPSIS</div>
  </div>
</div>

---
layout: ugm-section
---

<div class="section-content">
  <h1>Pendahuluan</h1>
  <p>
    Fokus proyek ini adalah mengubah proses pengambilan keputusan yang biasanya rumit dan manual menjadi alur yang lebih jelas, interaktif, dan terukur.
  </p>
</div>

---
layout: ugm-content
---

# Masalah yang Ingin Diselesaikan

<div class="one-col-copy">
  <div class="lead-box">
    Banyak keputusan penting gagal disusun dengan baik karena pengguna harus memikirkan terlalu banyak faktor sekaligus dan belum tentu paham cara menghitung prioritas tiap alternatif.
  </div>

  <ul class="reason-list">
    <li>Pengguna sering kesulitan menerjemahkan kebutuhan nyata menjadi kriteria, bobot, dan alternatif yang rapi.</li>
    <li>Metode seperti SAW, WP, AHP, dan TOPSIS kuat secara matematis, tetapi tidak ramah bagi pengguna non-teknis.</li>
    <li>Proses manual rawan bias, melelahkan, dan memperlambat keputusan karena perbandingan dilakukan tanpa struktur yang konsisten.</li>
  </ul>
</div>

<div class="highlight-strip">
  Tantangannya bukan hanya menghitung hasil, tetapi membantu pengguna membangun model keputusan yang benar sejak awal.
</div>

---
layout: ugm-content
---

# Ide Solusi

<div class="two-col cards">
  <div class="mini-card">
    <h3>Conversational guidance</h3>
    <p>AI berperan sebagai fasilitator yang menggali konteks keputusan, mengarahkan input pengguna, dan memastikan data yang dibutuhkan terkumpul secara bertahap.</p>
  </div>
  <div class="mini-card">
    <h3>Structured DSS engine</h3>
    <p>Setelah data siap, sistem menyusun matriks keputusan dan menghitung ranking menggunakan metode DSS yang sesuai tanpa membebani pengguna dengan rumus.</p>
  </div>
  <div class="mini-card">
    <h3>User-friendly explanation</h3>
    <p>Hasil akhir tidak berhenti pada angka ranking, tetapi dijelaskan kembali dalam bahasa yang lebih mudah dipahami untuk membantu keputusan final.</p>
  </div>
  <div class="mini-card">
    <h3>Persistent workflow</h3>
    <p>Riwayat sesi disimpan agar kasus keputusan dapat dibuka ulang, diperbaiki, atau dipakai lagi sebagai dasar evaluasi berikutnya.</p>
  </div>
</div>

<div class="highlight-strip">
  Nilai utama sistem ini adalah menggabungkan pengalaman AI yang natural dengan ketelitian metode DSS yang formal.
</div>

---
layout: ugm-content
---

# Alur Kerja Sistem

<div class="method-layout">
  <div class="mini-card points-card">
    <h3>Tahapan utama</h3>
    <ul class="reason-list">
      <li>Pengguna menjelaskan keputusan yang ingin dibuat dalam bentuk percakapan.</li>
      <li>AI menggali kriteria, jenis benefit atau cost, bobot, dan daftar alternatif.</li>
      <li>Sistem menyusun data menjadi matriks keputusan yang siap dihitung.</li>
      <li>Pengguna memilih metode atau membandingkan beberapa metode sekaligus.</li>
      <li>Hasil ranking ditampilkan bersama interpretasi yang lebih mudah dibaca.</li>
    </ul>
  </div>
  <div class="mini-card">
    <h3>Arsitektur singkat</h3>
    <p>Flutter menangani UI percakapan, DeepSeek membantu ekstraksi informasi, Firebase menyimpan histori, dan engine DSS lokal menjalankan perhitungan akhir.</p>
    <div class="reason-conclusion">
      AI dipakai untuk memandu dan memahami konteks, bukan untuk menggantikan logika matematis inti.
    </div>
  </div>
</div>

---
layout: ugm-content
---

# Metode yang Didukung

<div class="table-note">
  Sistem mendukung beberapa pendekatan agar pengguna bisa memilih metode yang paling sesuai dengan karakter keputusan yang sedang dihadapi.
</div>

<table class="result-table">
  <thead>
    <tr>
      <th>Metode</th>
      <th>Kegunaan Utama</th>
      <th>Kelebihan</th>
      <th>Catatan</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>SAW</strong></td>
      <td>Perbandingan berbobot yang sederhana</td>
      <td>Mudah dijelaskan dan cepat dihitung</td>
      <td>Cocok untuk kasus keputusan umum</td>
    </tr>
    <tr>
      <td><strong>WP</strong></td>
      <td>Penilaian berbasis perkalian bobot</td>
      <td>Menangkap efek proporsional antar kriteria</td>
      <td>Baik untuk data yang sensitif pada rasio</td>
    </tr>
    <tr>
      <td><strong>AHP</strong></td>
      <td>Pembobotan lewat perbandingan berpasangan</td>
      <td>Membantu saat prioritas kriteria belum jelas</td>
      <td>Bagus untuk membangun bobot secara sistematis</td>
    </tr>
    <tr>
      <td><strong>TOPSIS</strong></td>
      <td>Mencari alternatif terdekat ke solusi ideal</td>
      <td>Kuat untuk analisis komparatif multi-kriteria</td>
      <td>Memudahkan pembacaan posisi terbaik dan terburuk</td>
    </tr>
  </tbody>
</table>

<div class="highlight-strip">
  Dengan banyak metode, sistem tidak memaksa satu sudut pandang saja dalam menghasilkan rekomendasi.
</div>

---
layout: ugm-section
---

<div class="section-content">
  <h1>Nilai Produk</h1>
  <p>
    Selain menghitung ranking, aplikasi ini dirancang untuk mengurangi beban berpikir pengguna dan mempercepat transisi dari kebingungan menuju keputusan yang dapat dipertanggungjawabkan.
  </p>
</div>

---
layout: ugm-content
---

# Mengapa Pendekatan Ini Menarik

<div class="two-col cards">
  <div class="mini-card">
    <h3>Mathematically grounded</h3>
    <p>Keputusan tetap ditopang metode yang jelas, bukan hanya respons generatif yang terdengar meyakinkan.</p>
  </div>
  <div class="mini-card">
    <h3>Socially intelligent</h3>
    <p>Antarmuka chat membuat proses input lebih natural dan lebih dekat dengan cara pengguna berpikir saat berdiskusi.</p>
  </div>
  <div class="mini-card">
    <h3>Decisively faster</h3>
    <p>Struktur pertanyaan yang dibantu AI mempercepat penyusunan model keputusan dibanding mengisi tabel dari nol.</p>
  </div>
  <div class="mini-card">
    <h3>Reusable and traceable</h3>
    <p>Riwayat keputusan dapat disimpan, ditinjau ulang, dan dipakai lagi untuk iterasi keputusan berikutnya.</p>
  </div>
</div>

---
layout: ugm-content
---

# Nilai Tambah Utama

<div class="method-layout">
  <div class="mini-card points-card">
    <h3>General-purpose</h3>
    <ul class="reason-list">
      <li>Aplikasi ini tidak dibangun hanya untuk satu masalah spesifik.</li>
      <li>Alur yang sama dapat dipakai untuk keputusan personal, akademik, bisnis, dan konteks multi-kriteria lain.</li>
      <li>Pendekatan ini membuat sistem lebih fleksibel untuk dikembangkan ke banyak use case.</li>
    </ul>
  </div>
  <div class="mini-card">
    <h3>Implikasi produk</h3>
    <p>Nilai jualnya bukan sekadar fitur chat atau perhitungan metode, tetapi kemampuan untuk menjadi kerangka keputusan yang bisa dipakai lintas domain.</p>
    <div class="reason-conclusion">
      Satu aplikasi dapat melayani banyak jenis keputusan tanpa perlu didesain ulang untuk setiap masalah.
    </div>
  </div>
</div>

---
layout: ugm-content
---

# Tampilan Awal dan Percakapan

<div class="two-col">
  <div>
    <div class="image-panel tall-image-panel">
      <img src="./Simulator Screenshot - iPhone 17 Pro - 2026-04-10 at 22.09.20.png" alt="Halaman login aplikasi" />
    </div>
    <p class="figure-caption">
      Halaman masuk aplikasi.
    </p>
  </div>
  <div>
    <div class="image-panel tall-image-panel">
      <img src="./Simulator Screenshot - iPhone 17 Pro - 2026-04-10 at 22.09.38.png" alt="Halaman chat utama aplikasi" />
    </div>
    <p class="figure-caption">
      Chat utama dengan prompt dan kategori keputusan.
    </p>
  </div>
</div>

---
layout: ugm-content
---

# Riwayat dan Hasil Keputusan

<div class="two-col">
  <div>
    <div class="image-panel tall-image-panel">
      <img src="./Simulator Screenshot - iPhone 17 Pro - 2026-04-10 at 22.15.34.png" alt="Halaman riwayat keputusan" />
    </div>
    <p class="figure-caption">
      Riwayat sesi keputusan yang tersimpan.
    </p>
  </div>
  <div>
    <div class="image-panel tall-image-panel">
      <img src="./Simulator Screenshot - iPhone 17 Pro - 2026-04-10 at 22.15.54.png" alt="Modal wawasan keputusan dan ranking" />
    </div>
    <p class="figure-caption">
      Ringkasan ranking dan metode terpilih.
    </p>
  </div>
</div>

---
layout: ugm-quote
---

<div class="quote-content">
  <p class="quote-text">
    AI-Assisted DSS memindahkan proses pengambilan keputusan dari aktivitas yang melelahkan menjadi percakapan yang terarah, terukur, dan lebih mudah dipertanggungjawabkan.
  </p>

  <p class="quote-note">
    Terima kasih. Diskusi dapat difokuskan pada alur interaksi, cakupan metode, dan prioritas pengembangan selanjutnya.
  </p>
</div>
