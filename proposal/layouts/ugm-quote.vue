<template>
  <div class="ugm-layout ugm-quote-layout">
    <img src="../assets/ugm-wordmark.png" alt="Universitas Gadjah Mada" class="ugm-wordmark quote-wordmark" />
    <div class="quote-bg"></div>
    <div class="quote-main">
      <slot />
    </div>
    <div class="ugm-right-bars">
      <div class="bar-yellow"></div>
      <div class="bar-blue"></div>
    </div>
    <div class="quote-footer-left">Merakyat, Mandiri, Berkelanjutan<br>Inclusive, Self-Reliant, Sustainable</div>
    <div class="quote-footer-right">ugm.ac.id</div>
  </div>
</template>
