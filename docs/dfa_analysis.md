# Анализ потоков данных (Data Flow Analysis)

## 1. Цепочки Def-Use

* **Переменная: `log_entry`**
  * **Def 1:** строка 2 (`log_entry = "Start processing"`) — *значение перезаписывается без чтения*
  * **Def 2:** строка 10 (`log_entry = "Transaction finished with status: " + status`)
  * **Use:** строка 13 (`file.write(log_entry)`)

* **Переменная: `status`**
  * **Def:** строка 5 (`status = "approved"`) — *определяется только внутри ветки `if amount > 0`*
  * **Use 1:** строка 10 (`"Transaction finished with status: " + status`)
  * **Use 2:** строка 15 (`return status`)

* **Переменная: `balance`**
  * **Def:** строка 6 (`balance = get_balance(user_id)`)
  * **Use:** строка 7 (`new_balance = balance - amount`)

* **Переменная: `new_balance`**
  * **Def:** строка 7 (`new_balance = balance - amount`)
  * **Use:** строка 8 (`update_balance(user_id, new_balance)`)

* **Переменная: `file`**
  * **Def:** строка 12 (`file = open("audit_log.txt", "w")`)
  * **Use:** строка 13 (`file.write(log_entry)`)

## 2. Выявленные скрытые дефекты

1. **Использование неинициализированной переменной (`UnboundLocalError`):**
   На строках 10 и 15 происходит чтение переменной `status`. Если условие `amount > 0` (строка 4) не выполнится (например, `amount <= 0`), блок `if` будет пропущен, переменная `status` не получит значения и программа аварийно завершится с исключением `UnboundLocalError`.
2. **Мертвое присваивание (Dead Store):**
   На строке 2 переменной `log_entry` присваивается значение `"Start processing"`, но до следующего переопределения на строке 10 это значение нигде не читается и не записывается в лог.
3. **Утечка ресурса (Resource Leak):**
   На строке 12 открывается файловый дескриптор `file = open("audit_log.txt", "w")`, но метод `file.close()` нигде не вызывается (и не используется менеджер контекста `with`). При длительной работе сервиса это приведет к исчерпанию лимита открытых файлов ОС и возможной потере буферизованных данных.

