<template>
  <div class="ugm-layout ugm-cover-layout">
    <div class="ugm-cover-left">
      <img src="../assets/ugm-wordmark.png" alt="Universitas Gadjah Mada" class="ugm-wordmark cover-wordmark" />
      <div class="cover-sketch"></div>
      <div class="cover-domain">ugm.ac.id</div>
      <div class="cover-circle"></div>
    </div>
    <div class="ugm-cover-main">
      <slot />
    </div>
    <div class="ugm-right-bars">
      <div class="bar-yellow"></div>
      <div class="bar-blue"></div>
    </div>
    <div class="cover-tagline">Merakyat, Mandiri, Berkelanjutan<br>Inclusive, Self-Reliant, Sustainable</div>
  </div>
</template>
