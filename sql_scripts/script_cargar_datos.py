import pandas as pd
from sqlalchemy import create_engine

# Configura la conexión
user = 'root' #usuario
password = 'root' #password de usuario
host = 'localhost' #direccion del servidor 
database = 'sales_company'  #base de datos 
table_name = 'sales'  # Nombre de tabla que se inyectaran los datos

# Crear motor de conexión
engine = create_engine(f'mysql+pymysql://{user}:{password}@{host}/{database}')

# Ruta al archivo CSV
csv_file = r'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\sales.csv'  # Direccion del archivo

# Tamaño del bloque
chunk_size = 100000  #cantidad datos que se ingresaran por bloque

# Leer e insertar por bloques
for i, chunk in enumerate(pd.read_csv(csv_file, chunksize=chunk_size)):
    print(f"Insertando bloque {i+1}...")
    chunk.to_sql(name=table_name, con=engine, if_exists='append', index=False)

print("Importación completada.")
