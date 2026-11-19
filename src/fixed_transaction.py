def get_balance(user_id):
    return 1000


def update_balance(user_id, new_balance):
    pass


def process_transaction(user_id, amount, db_connection):
    status = "pending"
    log_entries = ["Start processing"]

    if amount > 0:
        status = "approved"
        balance = get_balance(user_id)
        new_balance = balance - amount
        update_balance(user_id, new_balance)

    log_entries.append(f"Transaction finished with status: {status}")

    with open("audit_log.txt", "w", encoding="utf-8") as file:
        file.write("\n".join(log_entries) + "\n")

    return status
