let Hooks = {};
Hooks.SubmitOnEnter = {
  mounted() {
    this.el.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();

        const form = this.el.closest("form");
        if (form) {
          form.requestSubmit();
        }
      }
    });
  },
};

export default Hooks;
