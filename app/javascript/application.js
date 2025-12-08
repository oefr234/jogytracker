import "@popperjs/core"
import "bootstrap"

async function apiFetch(url, options = {}) {
    const token = localStorage.getItem("token");

    const headers = {
        "Content-Type": "application/json",
        ...(options.headers || {}),
    };
    if (token) headers["Authorization"] = "Token token=" + token;

    const res = await fetch(url, { ...options, headers });

    if (res.status === 401 || res.status === 403) {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        sessionStorage.setItem("flash", "You must log in to continue.");
        window.location = "/login";
        return;
    }

    return res;
}
