import streamlit as st
import pandas as pd
import snowflake.connector
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import os

st.set_page_config(
    page_title="STERIS Predictive Maintenance",
    page_icon="🏭",
    layout="wide",
    initial_sidebar_state="expanded"
)

@st.cache_resource
def get_connection():
    return snowflake.connector.connect(
        connection_name=os.getenv("SNOWFLAKE_CONNECTION_NAME") or "default"
    )

@st.cache_data(ttl=300)
def run_query(query):
    conn = get_connection()
    return pd.read_sql(query, conn)

def get_fleet_summary():
    return run_query("""
        SELECT * FROM STERIS_RELIABILITY_DB.ANALYTICS.VW_FLEET_SUMMARY
    """)

def get_asset_health():
    return run_query("""
        SELECT * FROM STERIS_RELIABILITY_DB.ANALYTICS.VW_ASSET_HEALTH_DASHBOARD
        ORDER BY RISK_SCORE DESC
    """)

def get_high_risk_assets():
    return run_query("""
        SELECT * FROM STERIS_RELIABILITY_DB.ANALYTICS.VW_HIGH_RISK_ASSETS
        ORDER BY RISK_SCORE DESC
    """)

def get_maintenance_kpis():
    return run_query("""
        SELECT * FROM STERIS_RELIABILITY_DB.ANALYTICS.VW_MAINTENANCE_KPIS
    """)

def get_cost_avoidance():
    return run_query("""
        SELECT * FROM STERIS_RELIABILITY_DB.ANALYTICS.VW_COST_AVOIDANCE_TRACKING
    """)

def get_sensor_trends(asset_id):
    return run_query(f"""
        SELECT 
            FEATURE_DATE,
            VIBRATION_DAILY_AVG,
            MOTOR_CURRENT_DAILY_AVG,
            MOTOR_TEMP_DAILY_AVG,
            ANOMALY_HOURS
        FROM STERIS_RELIABILITY_DB.FEATURES.VW_ASSET_FEATURES_DAILY
        WHERE ASSET_ID = '{asset_id}'
        ORDER BY FEATURE_DATE
    """)

st.title("🏭 STERIS Factory of the Future")
st.markdown("### Predictive Maintenance Dashboard")

page = st.sidebar.radio(
    "Navigation",
    ["📊 Executive Summary", "🔍 Asset Health", "⚠️ High Risk Assets", 
     "📈 Trends Analysis", "💰 Cost Avoidance", "🔧 Maintenance KPIs"]
)

if page == "📊 Executive Summary":
    st.header("Fleet Health Overview")
    
    fleet = get_fleet_summary()
    
    if not fleet.empty:
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric(
                "Total Assets", 
                int(fleet['TOTAL_ASSETS'].iloc[0]),
                help="Total number of monitored assets"
            )
        with col2:
            st.metric(
                "Average Health Index", 
                f"{fleet['AVG_HEALTH_INDEX'].iloc[0]:.1f}%",
                help="Fleet-wide average health score"
            )
        with col3:
            st.metric(
                "Average Risk Score", 
                f"{fleet['AVG_RISK_SCORE'].iloc[0]:.1f}",
                help="Fleet-wide average risk (0-100)"
            )
        with col4:
            st.metric(
                "Avg RUL", 
                f"{fleet['AVG_RUL_DAYS'].iloc[0]:.0f} days",
                help="Average remaining useful life"
            )
        
        st.divider()
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Risk Distribution")
            risk_data = pd.DataFrame({
                'Level': ['Low', 'Medium', 'High', 'Critical'],
                'Count': [
                    fleet['ASSETS_LOW_RISK'].iloc[0],
                    fleet['ASSETS_MEDIUM_RISK'].iloc[0],
                    fleet['ASSETS_HIGH_RISK'].iloc[0],
                    fleet['ASSETS_CRITICAL'].iloc[0]
                ]
            })
            fig = px.pie(
                risk_data, 
                values='Count', 
                names='Level',
                color='Level',
                color_discrete_map={
                    'Low': '#28a745',
                    'Medium': '#ffc107',
                    'High': '#fd7e14',
                    'Critical': '#dc3545'
                }
            )
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.subheader("Financial Impact")
            st.metric(
                "Potential Loss at Risk",
                f"${fleet['POTENTIAL_LOSS_K_USD'].iloc[0]:,.0f}K",
                help="Estimated financial exposure from at-risk assets"
            )
            st.metric(
                "Total Hourly Impact",
                f"${fleet['TOTAL_HOURLY_IMPACT'].iloc[0]:,.0f}/hr",
                help="Combined production impact if all assets fail"
            )

elif page == "🔍 Asset Health":
    st.header("Asset Health Dashboard")
    
    assets = get_asset_health()
    
    if not assets.empty:
        asset_types = ['All'] + list(assets['ASSET_TYPE'].unique())
        selected_type = st.selectbox("Filter by Asset Type", asset_types)
        
        if selected_type != 'All':
            assets = assets[assets['ASSET_TYPE'] == selected_type]
        
        fig = px.scatter(
            assets,
            x='EQUIPMENT_HEALTH_INDEX',
            y='RISK_SCORE',
            color='ALERT_LEVEL',
            size='PRODUCTION_IMPACT_HOURLY_USD',
            hover_data=['ASSET_ID', 'ASSET_NAME', 'PREDICTED_RUL_DAYS'],
            color_discrete_map={
                'LOW': '#28a745',
                'MEDIUM': '#ffc107',
                'HIGH': '#fd7e14',
                'CRITICAL': '#dc3545'
            },
            labels={
                'EQUIPMENT_HEALTH_INDEX': 'Health Index (%)',
                'RISK_SCORE': 'Risk Score',
                'ALERT_LEVEL': 'Alert Level'
            },
            title="Asset Health vs Risk Matrix"
        )
        fig.update_layout(height=500)
        st.plotly_chart(fig, use_container_width=True)
        
        st.subheader("Asset Details")
        st.dataframe(
            assets[['ASSET_ID', 'ASSET_NAME', 'ASSET_TYPE', 'RISK_SCORE', 
                   'ALERT_LEVEL', 'EQUIPMENT_HEALTH_INDEX', 'PREDICTED_RUL_DAYS',
                   'DAYS_SINCE_MAINTENANCE']].round(2),
            hide_index=True,
            use_container_width=True
        )

elif page == "⚠️ High Risk Assets":
    st.header("High Risk Assets - Requires Attention")
    
    high_risk = get_high_risk_assets()
    
    if not high_risk.empty:
        for _, asset in high_risk.iterrows():
            alert_color = {
                'CRITICAL': '🔴',
                'HIGH': '🟠',
                'MEDIUM': '🟡',
                'LOW': '🟢'
            }.get(asset['ALERT_LEVEL'], '⚪')
            
            with st.expander(f"{alert_color} {asset['ASSET_NAME']} ({asset['ASSET_ID']}) - Risk: {asset['RISK_SCORE']:.1f}", expanded=asset['RISK_SCORE'] > 40):
                col1, col2, col3 = st.columns(3)
                
                with col1:
                    st.metric("Risk Score", f"{asset['RISK_SCORE']:.1f}")
                    st.metric("Alert Level", asset['ALERT_LEVEL'])
                
                with col2:
                    st.metric("Failure Probability", f"{asset['FAILURE_PROBABILITY_PCT']:.1f}%")
                    st.metric("Predicted RUL", f"{asset['PREDICTED_RUL_DAYS']:.0f} days")
                
                with col3:
                    st.metric("Mechanical Stress", f"{asset['MECHANICAL_STRESS_INDEX']:.1f}%")
                    st.metric("Days Since Maint.", f"{asset['DAYS_SINCE_MAINTENANCE']:.0f}")
                
                st.info(f"**Recommended Action:** {asset['RECOMMENDED_ACTION']}")
                
                if pd.notna(asset.get('POTENTIAL_LOSS_IF_UNADDRESSED_K_USD')):
                    st.warning(f"**Potential Financial Impact:** ${asset['POTENTIAL_LOSS_IF_UNADDRESSED_K_USD']:,.0f}K")
    else:
        st.success("✅ No high-risk assets detected!")

elif page == "📈 Trends Analysis":
    st.header("Sensor Trends Analysis")
    
    assets = get_asset_health()
    
    if not assets.empty:
        selected_asset = st.selectbox(
            "Select Asset",
            assets['ASSET_ID'].tolist(),
            format_func=lambda x: f"{x} - {assets[assets['ASSET_ID']==x]['ASSET_NAME'].iloc[0]}"
        )
        
        trends = get_sensor_trends(selected_asset)
        
        if not trends.empty:
            col1, col2 = st.columns(2)
            
            with col1:
                fig = px.line(
                    trends,
                    x='FEATURE_DATE',
                    y='VIBRATION_DAILY_AVG',
                    title='Vibration Trend (mm/s)',
                    labels={'VIBRATION_DAILY_AVG': 'Vibration', 'FEATURE_DATE': 'Date'}
                )
                fig.add_hline(y=2.5, line_dash="dash", line_color="orange", annotation_text="Warning")
                fig.add_hline(y=3.5, line_dash="dash", line_color="red", annotation_text="Alarm")
                st.plotly_chart(fig, use_container_width=True)
            
            with col2:
                fig = px.line(
                    trends,
                    x='FEATURE_DATE',
                    y='MOTOR_CURRENT_DAILY_AVG',
                    title='Motor Current Trend (A)',
                    labels={'MOTOR_CURRENT_DAILY_AVG': 'Current', 'FEATURE_DATE': 'Date'}
                )
                st.plotly_chart(fig, use_container_width=True)
            
            col1, col2 = st.columns(2)
            
            with col1:
                fig = px.line(
                    trends,
                    x='FEATURE_DATE',
                    y='MOTOR_TEMP_DAILY_AVG',
                    title='Motor Temperature Trend (°C)',
                    labels={'MOTOR_TEMP_DAILY_AVG': 'Temperature', 'FEATURE_DATE': 'Date'}
                )
                st.plotly_chart(fig, use_container_width=True)
            
            with col2:
                fig = px.bar(
                    trends.tail(30),
                    x='FEATURE_DATE',
                    y='ANOMALY_HOURS',
                    title='Daily Anomaly Hours (Last 30 Days)',
                    labels={'ANOMALY_HOURS': 'Hours', 'FEATURE_DATE': 'Date'}
                )
                st.plotly_chart(fig, use_container_width=True)

elif page == "💰 Cost Avoidance":
    st.header("Cost Avoidance Tracking")
    
    costs = get_cost_avoidance()
    
    if not costs.empty:
        total_savings = costs['EXPECTED_SAVINGS_PM'].sum()
        total_avoidable = costs['TOTAL_AVOIDABLE_COST'].sum()
        
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.metric("Expected Annual Savings", f"${total_savings:,.0f}")
        with col2:
            st.metric("Total Avoidable Costs", f"${total_avoidable:,.0f}")
        with col3:
            roi = (total_savings / total_avoidable * 100) if total_avoidable > 0 else 0
            st.metric("PM ROI", f"{roi:.0f}%")
        
        st.divider()
        
        fig = px.bar(
            costs.nlargest(10, 'EXPECTED_SAVINGS_PM'),
            x='ASSET_NAME',
            y=['EST_REPAIR_COST', 'EST_PRODUCTION_LOSS'],
            title='Top 10 Assets by Cost Avoidance Potential',
            labels={'value': 'Cost ($)', 'ASSET_NAME': 'Asset'},
            barmode='stack'
        )
        st.plotly_chart(fig, use_container_width=True)
        
        st.subheader("Detailed Breakdown")
        st.dataframe(
            costs[['ASSET_ID', 'ASSET_NAME', 'RISK_SCORE', 'EST_REPAIR_COST',
                  'EST_PRODUCTION_LOSS', 'TOTAL_AVOIDABLE_COST', 'EXPECTED_SAVINGS_PM']].round(2),
            hide_index=True,
            use_container_width=True
        )

elif page == "🔧 Maintenance KPIs":
    st.header("Maintenance Performance KPIs")
    
    kpis = get_maintenance_kpis()
    
    if not kpis.empty:
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            avg_mttr = kpis['MTTR_HOURS'].mean()
            st.metric("Avg MTTR", f"{avg_mttr:.1f} hrs", help="Mean Time To Repair")
        
        with col2:
            avg_mtbf = kpis['MTBF_DAYS'].mean()
            st.metric("Avg MTBF", f"{avg_mtbf:.0f} days", help="Mean Time Between Failures")
        
        with col3:
            avg_avail = kpis['AVAILABILITY_PCT'].mean()
            st.metric("Avg Availability", f"{avg_avail:.1f}%")
        
        with col4:
            avg_pm = kpis['PM_COMPLIANCE_PCT'].mean()
            st.metric("PM Compliance", f"{avg_pm:.0f}%")
        
        st.divider()
        
        col1, col2 = st.columns(2)
        
        with col1:
            fig = px.bar(
                kpis.groupby('ASSET_TYPE').agg({
                    'CORRECTIVE_MAINTENANCE': 'sum',
                    'PREVENTIVE_MAINTENANCE': 'sum'
                }).reset_index(),
                x='ASSET_TYPE',
                y=['CORRECTIVE_MAINTENANCE', 'PREVENTIVE_MAINTENANCE'],
                title='Work Orders by Asset Type',
                barmode='group',
                labels={'value': 'Count', 'ASSET_TYPE': 'Asset Type'}
            )
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            fig = px.bar(
                kpis.nlargest(10, 'YTD_MAINTENANCE_COST'),
                x='ASSET_NAME',
                y='YTD_MAINTENANCE_COST',
                title='Top 10 Assets by Maintenance Cost',
                labels={'YTD_MAINTENANCE_COST': 'Cost ($)', 'ASSET_NAME': 'Asset'}
            )
            st.plotly_chart(fig, use_container_width=True)
        
        st.subheader("Asset KPI Details")
        st.dataframe(
            kpis[['ASSET_ID', 'ASSET_NAME', 'ASSET_TYPE', 'MTTR_HOURS', 
                 'MTBF_DAYS', 'AVAILABILITY_PCT', 'PM_COMPLIANCE_PCT',
                 'YTD_DOWNTIME_HOURS', 'YTD_MAINTENANCE_COST']].round(2),
            hide_index=True,
            use_container_width=True
        )

st.sidebar.divider()
st.sidebar.markdown("### About")
st.sidebar.markdown("""
**STERIS Factory of the Future**  
Predictive Maintenance AI System

Built with:
- Snowflake ML
- XGBoost / Isolation Forest
- Streamlit

*Last Updated: 2024*
""")

if st.sidebar.button("🔄 Refresh Scores"):
    try:
        conn = get_connection()
        conn.cursor().execute("CALL STERIS_RELIABILITY_DB.ML.SCORE_ASSETS_SQL()")
        st.cache_data.clear()
        st.success("Scores refreshed!")
        st.rerun()
    except Exception as e:
        st.error(f"Error: {e}")
