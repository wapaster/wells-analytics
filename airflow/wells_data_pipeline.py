from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.utils.email import send_email
from datetime import datetime, timedelta

default_args = {
    'owner': 'artur',
    'retries': 1,
    'retry_delay': timedelta(minutes=2),
    'email_on_failure': False,   # отключаем стандартные алерты — шлём свои, красивые
    'email': ['your_email@gmail.com'],
}

dag = DAG(
    dag_id='wells_data_update',
    default_args=default_args,
    description='Проверка доступности БД и обновление данных скважин',
    schedule_interval='*/15 * * * *',
    start_date=datetime(2026, 7, 1),
    catchup=False,
    tags=['wells', 'production'],
)


def send_pretty_alert(subject, title, message, color="#d32f2f"):
    """Отправляет красиво оформленное HTML-письмо."""
    html_content = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: {color}; padding: 20px; border-radius: 8px 8px 0 0;">
            <h2 style="color: white; margin: 0;">⚠ {title}</h2>
        </div>
        <div style="background: #f9f9f9; padding: 20px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 8px 8px;">
            <p style="font-size: 15px; color: #333; line-height: 1.6;">{message}</p>
            <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
            <p style="font-size: 12px; color: #999;">
                Wells Analytics Pipeline &middot; Airflow &middot;
                {datetime.now().strftime('%d.%m.%Y %H:%M')}
            </p>
        </div>
    </div>
    """
    send_email(
        to=['arturboranbaev13@gmail.com'],
        subject=subject,
        html_content=html_content
    )


def check_server_connection():
    hook = PostgresHook(postgres_conn_id='wells_postgres')
    try:
        conn = hook.get_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT 1;")
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        print("Сервер доступен, подключение успешно")
    except Exception as e:
        send_pretty_alert(
            subject="🔴 Wells Pipeline: сервер недоступен",
            title="Сервер базы данных недоступен",
            message=f"Не удалось подключиться к PostgreSQL (wells_analytics).<br>"
                    f"Ошибка: {str(e)}",
            color="#d32f2f"
        )
        raise


def check_data_freshness():
    hook = PostgresHook(postgres_conn_id='wells_postgres')
    result = hook.get_first("""
        SELECT MAX(test_date), CURRENT_DATE - MAX(test_date) AS days_old
        FROM agzu_tests;
    """)
    last_date, days_old = result
    print(f"Последний замер: {last_date}, возраст: {days_old} дней")

    if days_old is not None and days_old > 3:
        send_pretty_alert(
            subject=f"🟡 Wells Pipeline: данные устарели ({days_old} дн.)",
            title="Данные устарели",
            message=f"Последний замер АГЗУ: <b>{last_date}</b><br>"
                    f"Возраст данных: <b>{days_old} дней</b><br>"
                    f"Порог свежести: 3 дня<br><br>"
                    f"Рекомендуется проверить обновление данных из SCADA.",
            color="#f9a825"
        )
        raise Exception(
            f"Данные устарели: последний замер {last_date}, "
            f"это {days_old} дней назад"
        )


def update_summary_view():
    hook = PostgresHook(postgres_conn_id='wells_postgres')
    hook.run("SELECT COUNT(*) FROM v_well_summary;")
    print("Витрина v_well_summary доступна и рабочая")


check_connection_task = PythonOperator(
    task_id='check_server_connection',
    python_callable=check_server_connection,
    dag=dag,
)

check_freshness_task = PythonOperator(
    task_id='check_data_freshness',
    python_callable=check_data_freshness,
    dag=dag,
)

update_task = PythonOperator(
    task_id='update_summary_view',
    python_callable=update_summary_view,
    dag=dag,
)

check_connection_task >> check_freshness_task >> update_task