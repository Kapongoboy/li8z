import "./style.css";

document.querySelector<HTMLDivElement>("#app")!.innerHTML = `
  <div>
    <h1>Li8z chip8-emulator</h1>
  </div>
`;

document.addEventListener("keydown", (event) => {
  console.log(`Key Pressed: ${event.key}`);
});

document.addEventListener("keyup", (event) => {
  console.log(`Key Released: ${event.key}`);
});
