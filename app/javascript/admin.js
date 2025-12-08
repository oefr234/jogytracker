document.addEventListener("DOMContentLoaded", () => {
    const token = localStorage.getItem("token");
    if (!token) window.location = "/login";

    const auth = () => ({
        Authorization: "Token token=" + token,
        "Content-Type": "application/json",
    });

    const showAlert = (message, type = "success") => {
        const alertBox = document.getElementById("alertBox");
        alertBox.innerHTML = `
      <div class="alert alert-${type} alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>`;
    };

    const loadUsers = async () => {
        const res = await fetch("/api/users", { headers: auth() });
        if (!res.ok) {
            document.body.innerHTML = `<div class="container py-5 text-center"><h3>Forbidden</h3></div>`;
            return;
        }
        const users = await res.json();
        const tbody = document.querySelector("#usersTbl tbody");
        tbody.innerHTML = "";
        users.forEach((u) => {
            const tr = document.createElement("tr");
            tr.innerHTML = `
        <td>${u.id}</td>
        <td>${u.name}</td>
        <td>${u.email}</td>
        <td><span class="badge bg-${
                u.role === "admin"
                    ? "danger"
                    : u.role === "user_manager"
                        ? "info"
                        : "secondary"
            }">${u.role}</span></td>
        <td class="text-end">
          <button data-id="${u.id}" class="btn btn-sm btn-outline-danger delBtn">
            <i class="bi bi-trash"></i> Delete
          </button>
        </td>`;
            tbody.appendChild(tr);
        });
    };

    document.getElementById("reloadBtn")?.addEventListener("click", loadUsers);

    document.getElementById("createUserBtn")?.addEventListener("click", async () => {
        const user = {
            name: document.getElementById("newName").value.trim(),
            email: document.getElementById("newEmail").value.trim(),
            role: document.getElementById("newRole").value,
            password: document.getElementById("newPass").value,
        };
        const res = await fetch("/api/users", {
            method: "POST",
            headers: auth(),
            body: JSON.stringify({ user }),
        });
        if (res.ok) {
            showAlert("User created successfully ✅");
            document.getElementById("newUserForm").reset();
            loadUsers();
        } else {
            const err = await res.json();
            showAlert(err.errors?.join(", ") || err.error, "danger");
        }
    });

    document.getElementById("usersTbl")?.addEventListener("click", async (e) => {
        const btn = e.target.closest(".delBtn");
        if (btn) {
            const id = btn.dataset.id;
            if (!confirm("Delete this user?")) return;
            const res = await fetch(`/api/users/${id}`, {
                method: "DELETE",
                headers: auth(),
            });
            if (res.ok) {
                showAlert("User deleted successfully 🗑️", "warning");
                loadUsers();
            } else {
                showAlert("Failed to delete user", "danger");
            }
        }
    });

    loadUsers();
});
