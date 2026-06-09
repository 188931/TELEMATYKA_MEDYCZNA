import flet as ft
import requests
from datetime import datetime

def main(page: ft.Page):
    page.title = "Aplikacji wspomagania pielęgniarki środowiskowej"
    page.theme_mode = ft.ThemeMode.LIGHT
    page.padding = 20
    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER

    def process_login(username, password, role, dialog):
        payload = {"username": username, "password": password, "role": role}
        try:
            res = requests.post("http://127.0.0.1:8000/login/", json=payload)
            data = res.json()
            
            if res.status_code == 200 and data.get("status") == "success":
                dialog.open = False
                page.clean()
                page.vertical_alignment = ft.MainAxisAlignment.START
                
                if role == "nurse":
                    build_nurse_dashboard(data["user"]["full_name"])
                else:
                    build_patient_portal(data["user"]["username"], data["user"]["full_name"], is_nurse=False)
                
                page.update()
            else:
                page.show_dialog(ft.SnackBar(ft.Text("Błąd: " + data.get("message", "Nieznany błąd")), bgcolor="red"))
                page.update()
        except Exception as e:
            print(f"Błąd logowania: {e}")

    def show_login_dialog(role):
        user_field = ft.TextField(label="Login", icon=ft.Icons.PERSON)
        pass_field = ft.TextField(label="Hasło", password=True, can_reveal_password=True, icon=ft.Icons.LOCK)
        
        def handle_login_attempt(e):
            process_login(user_field.value, pass_field.value, role, login_dlg)

        login_dlg = ft.AlertDialog(
            title=ft.Text(f"Logowanie: {'Pielęgniarka' if role == 'nurse' else 'Pacjent'}"),
            content=ft.Column([user_field, pass_field], tight=True),
            actions=[
                ft.TextButton("Anuluj", on_click=lambda _: (setattr(login_dlg, "open", False), page.update())),
                ft.FilledButton("Zaloguj", on_click=handle_login_attempt)
            ]
        )
        page.overlay.append(login_dlg)
        login_dlg.open = True
        page.update()

    def show_welcome_screen():
        page.clean()
        page.title = "Aplikacja wspomagania pielęgniarki środowiskowej"
        page.scroll = None 
        page.vertical_alignment = ft.MainAxisAlignment.CENTER
        page.horizontal_alignment = ft.CrossAxisAlignment.CENTER
        page.floating_action_button = None

        nurse_card = ft.Card(
            content=ft.Container(
                content=ft.Column([
                    ft.Icon(ft.Icons.LOCAL_HOSPITAL, size=50, color=ft.Colors.BLUE),
                    ft.Text("Panel Pielęgniarki", size=20, weight="bold"),
                    ft.ElevatedButton("Wybierz", on_click=lambda _: show_login_dialog("nurse"))
                ], horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                padding=30, width=250
            )
        )

        patient_card = ft.Card(
            content=ft.Container(
                content=ft.Column([
                    ft.Icon(ft.Icons.PERSON, size=50, color=ft.Colors.GREEN),
                    ft.Text("Portal Pacjenta", size=20, weight="bold"),
                    ft.ElevatedButton("Wybierz", on_click=lambda _: show_login_dialog("patient"))
                ], horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                padding=30, width=250
            )
        )

        page.add(
            ft.Row([nurse_card, patient_card], alignment=ft.MainAxisAlignment.CENTER)
        )
        page.update()

    def build_nurse_dashboard(nurse_name):
        page.clean()
        page.title = "Mobilna Pielęgniarka - Lista Pacjentów"
        page.theme_mode = ft.ThemeMode.LIGHT
        page.padding = 20
        
        API_URL = API_URL = "http://127.0.0.1:8000/patients-with-visits/"

        def get_patients():
            try:
                response = requests.get(API_URL)
                if response.status_code == 200:
                    return response.json()
                return []
            except Exception as e:
                print(f"Błąd połączenia: {e}")
                return []
        
        def open_visit_form(visit_id, patient_id, patient_name):
            sys_field = ft.TextField(label="Ciśnienie skurczowe", keyboard_type=ft.KeyboardType.NUMBER, suffix=ft.Text("mmHg"), icon=ft.Icons.MONITOR_HEART)
            dia_field = ft.TextField(label="Ciśnienie rozkurczowe", keyboard_type=ft.KeyboardType.NUMBER, suffix=ft.Text("mmHg"), icon=ft.Icons.MONITOR_HEART)
            hr_field = ft.TextField(label="Tętno", keyboard_type=ft.KeyboardType.NUMBER, suffix=ft.Text("bpm"), icon=ft.Icons.FAVORITE)
            glu_field = ft.TextField(label="Glikemia", keyboard_type=ft.KeyboardType.NUMBER, suffix=ft.Text("mg/dL"), icon=ft.Icons.WATER_DROP)
            notes_field = ft.TextField(label="Notatki z wizyty", multiline=True, min_lines=3, icon=ft.Icons.NOTE_ADD)

            def schedule_next_visit(p_id, p_name):
                new_date_field = ft.TextField(
                    label="Data kolejnej wizyty", 
                    hint_text="RRRR-MM-DD GG:MM:SS",
                    icon=ft.Icons.EVENT_REPEAT
                )

                def confirm_new_visit(e):
                    if not new_date_field.value:
                        return
                    
                    new_visit_payload = {
                        "patient_id": p_id, 
                        "visit_date": new_date_field.value
                    }
                    
                    try:
                        res = requests.post("http://127.0.0.1:8000/create-visit/", json=new_visit_payload)
                        if res.status_code == 200:
                            next_visit_dlg.open = False
                            page.update()
                            build_patients_list()
                    except Exception as ex:
                        print(f"Błąd tworzenia wizyty: {ex}")

                next_visit_dlg = ft.AlertDialog(
                    title=ft.Text(f"Zaplanuj następną wizytę"),
                    content=ft.Column([
                        ft.Text(f"Pacjent: {p_name}"),
                        new_date_field
                    ], tight=True),
                    actions=[
                        ft.FilledButton("Zatwierdź termin", on_click=confirm_new_visit)
                    ]
                )
                page.overlay.append(next_visit_dlg)
                next_visit_dlg.open = True
                page.update()

            def save_measurements(e):
                if not sys_field.value or not dia_field.value or not hr_field.value:
                    page.show_dialog(ft.SnackBar(ft.Text("Uzupełnij wymagane pola!"), bgcolor=ft.Colors.RED_700))
                    return
                
                payload = {
                    "visit_id": visit_id,
                    "blood_pressure_sys": int(sys_field.value or 0),
                    "blood_pressure_dia": int(dia_field.value or 0),
                    "heart_rate": int(hr_field.value or 0),
                    "glucose_level": float(glu_field.value or 0),
                    "notes": notes_field.value
                }
                try:
                    res = requests.post("http://127.0.0.1:8000/measurements/", json=payload)
                    if res.status_code == 200:
                        dlg.open = False
                        page.update()
                        page.show_dialog(ft.SnackBar(ft.Text(f"Wizyta zakończona. Pomiary zapisane!")))

                        build_patients_list()

                        schedule_next_visit(patient_id, patient_name)
                except Exception as ex:
                    print(f"Błąd zapisu: {ex}")

            dlg = ft.AlertDialog(
                title=ft.Text(f"Wizyta: {patient_name}"),
                content=ft.Container(
                    content=ft.Column([
                        ft.Divider(),
                        sys_field, 
                        dia_field, 
                        hr_field, 
                        glu_field, 
                        notes_field,
                    ], tight=True, spacing=10, scroll=ft.ScrollMode.AUTO),
                    width=400,
                ),
                actions=[
                    ft.TextButton("Anuluj", on_click=lambda _: (setattr(dlg, "open", False), page.update())),
                    ft.FilledButton("Zapisz parametry", on_click=save_measurements),
                ],
                actions_alignment=ft.MainAxisAlignment.END,
            )

            page.overlay.append(dlg)
            dlg.open = True
            page.update()

        def build_patients_list():
            patients_list.controls.clear()
            data = get_patients()
            now = datetime.now()

            for p in data:
                v_id = p.get('visit_id') 
                p_id = p.get('id')
                p_name = f"{p['first_name']} {p['last_name']}"
                p_pesel = p.get('pesel')
                v_date_str = p.get('visit_date')
                
                v_date_obj = datetime.strptime(v_date_str, "%Y-%m-%d %H:%M:%S")
                
                is_locked = now < v_date_obj

                def open_date_picker(e, visit_id, current_val):
                    date_field = ft.TextField(
                        label="Nowa data i godzina", 
                        value=current_val,
                        hint_text="RRRR-MM-DD GG:MM:SS"
                    )
                    
                    def confirm_date(e):
                        payload = {
                            "visit_id": int(visit_id),
                            "new_date": date_field.value
                        }
                        try:
                            res = requests.put("http://127.0.0.1:8000/update-visit-date/", json=payload)
                            if res.status_code == 200:
                                date_dlg.open = False
                                page.update()
                                build_patients_list()
                            else:
                                print(f"Błąd 422: {res.json()}") 
                        except Exception as ex:
                            print(f"Błąd: {ex}")

                    date_dlg = ft.AlertDialog(
                        title=ft.Text("Zmiana terminu"),
                        content=ft.Container(content=date_field, padding=10),
                        actions=[
                            ft.TextButton("Anuluj", on_click=lambda _: (setattr(date_dlg, "open", False), page.update())),
                            ft.FilledButton("Zaktualizuj", on_click=confirm_date)
                        ]
                    )
                    
                    page.overlay.append(date_dlg)
                    date_dlg.open = True
                    page.update()

                patients_list.controls.append(
                    ft.Card(
                        content=ft.Container(
                            padding=15,
                            content=ft.Column([
                                ft.ListTile(
                                    leading=ft.Icon(
                                        ft.Icons.LOCK if is_locked else ft.Icons.LOCK_OPEN, 
                                        color=ft.Colors.RED if is_locked else ft.Colors.GREEN
                                    ),
                                    title=ft.Text(p_name, weight="bold"),
                                    subtitle=ft.Text(f"WIZYTA: {v_date_str}\nStatus: {'Oczekuje' if is_locked else 'Można rozpocząć'}"),
                                ),
                                ft.Row([
                                    ft.Row([
                                        ft.IconButton(
                                            icon=ft.Icons.EDIT_CALENDAR, 
                                            on_click=lambda e, vid=v_id, val=v_date_str: open_date_picker(e, vid, val),
                                            tooltip="Zmień datę wizyty"
                                        ),
                                        ft.IconButton(
                                            icon=ft.Icons.PERSON_SEARCH, 
                                            icon_color=ft.Colors.BLUE_700,
                                            on_click=lambda e, pesel=p_pesel, name=p_name: build_patient_portal(pesel, name, is_nurse=True),
                                            tooltip="Szczegóły i historia pacjenta"
                                        ),
                                    ]),
                                    ft.FilledButton(
                                        "Rozpocznij wizytę",
                                        icon=ft.Icons.PLAY_ARROW,
                                        disabled=is_locked,
                                        on_click=lambda e, vid=v_id, pid=p_id, name=p_name: open_visit_form(vid, pid, name)
                                    )
                                ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN)
                            ])
                        )
                    )
                )
            page.update()
        
        header = ft.Text("Twoi Pacjenci", size=28, weight="bold")
        patients_list = ft.Column(scroll=ft.ScrollMode.AUTO, expand=True)
        
        refresh_btn = ft.FloatingActionButton(
            icon=ft.Icons.REFRESH, 
            on_click=lambda _: build_patients_list(),
            tooltip="Odśwież listę"
        )

        page.add(header, patients_list)
        page.floating_action_button = refresh_btn
        
        build_patients_list()
    
    def build_patient_portal(pesel, full_name, is_nurse=False):
        page.clean()
        page.title = f"Portal Pacjenta - {full_name}"
        page.scroll = ft.ScrollMode.AUTO
        
        def get_history():
            try:
                res = requests.get(f"http://127.0.0.1:8000/patient-history/{pesel}")
                return res.json() if res.status_code == 200 else []
            except:
                return []

        history_data = get_history()
        
        p_info = history_data[0] if history_data else {}
        
        profile_card = ft.Card(
            content=ft.Container(
                padding=20,
                content=ft.Column([
                    ft.Text("Dane pacjenta", size=24, weight="bold"),
                    ft.Divider(),
                    ft.Row([
                        ft.Icon(ft.Icons.PERSON, color="blue"),
                        ft.Text(f"Pacjent: {full_name} (PESEL: {pesel})", size=16)
                    ]),
                    ft.Row([
                        ft.Icon(ft.Icons.HOME, color="blue"),
                        ft.Text(f"Adres: {p_info.get('address', 'Brak danych')}")
                    ]),
                    ft.Row([
                        ft.Icon(ft.Icons.WARNING, color="red"),
                        ft.Text(f"Alergie: {p_info.get('allergies', 'Brak')}", color="red", weight="bold")
                    ]),
                    ft.Row([
                        ft.Icon(ft.Icons.MEDICAL_INFORMATION, color="orange"),
                        ft.Text(f"Choroby przewlekłe: {p_info.get('chronic_diseases', 'Brak')}")
                    ]),
                ])
            )
        )

        history_table = ft.DataTable(
            columns=[
                ft.DataColumn(ft.Text("Data wizyty")),
                ft.DataColumn(ft.Text("Ciśnienie")),
                ft.DataColumn(ft.Text("Tętno")),
                ft.DataColumn(ft.Text("Cukier")),
                ft.DataColumn(ft.Text("Notatki")),
            ],
            rows=[
                ft.DataRow(
                    cells=[
                        ft.DataCell(ft.Text(h['visit_date'])),
                        ft.DataCell(ft.Text(f"{h['blood_pressure_sys']}/{h['blood_pressure_dia']} mmHg")),
                        ft.DataCell(ft.Text(f"{h['heart_rate']} bpm")),
                        ft.DataCell(ft.Text(f"{h['glucose_level']} mg/dL")),
                        ft.DataCell(ft.Text(h['notes'] if h['notes'] else "-")),
                    ]
                ) for h in history_data
            ],
        )

        history_section = ft.Column([
            ft.Text("Historia pomiarów", size=24, weight="bold"),
            ft.Container(
                content=ft.Row([history_table], scroll=ft.ScrollMode.AUTO),
                padding=10,
            )
        ], scroll=ft.ScrollMode.AUTO, expand=True)

        if is_nurse:
            back_button = ft.Row([
                ft.IconButton(ft.Icons.ARROW_BACK, on_click=lambda _: build_nurse_dashboard(None)),
                ft.Text("Wróć do listy pacjentów", weight="bold")
            ], alignment=ft.MainAxisAlignment.START)
        else:
            back_button = ft.Row([
                ft.IconButton(ft.Icons.LOGOUT, on_click=lambda _: show_welcome_screen()),
                ft.Text("Wyloguj", weight="bold")
            ], alignment=ft.MainAxisAlignment.START)

        page.add(
            back_button,
            profile_card,
            ft.Divider(height=30, color="transparent"),
            history_section
        )
        page.update()
    
    show_welcome_screen()

ft.run(main)