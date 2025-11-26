import pandas as pd
import matplotlib.pyplot as plt


df = pd.read_csv("/Users/ffff/Result_15.csv")

interpretation = (
    "Average game prices on Steam changed gradually over the years, with a general trend\n "
    "of increasing costs.This rise is likely due to higher development expenses and more\n "
    "premium games being released.Occasional drops in average price can be explained by the\n "
    "growth of cheaper indie titles and frequent discounts.Overall, the price trend is mixed\n "
    "but slowly moving upward."
)

print(df)
print(interpretation)


plt.figure(figsize=(12, 6))

plt.plot(df["year"], df["avg_price"], marker="o", linewidth=2)

plt.title("Average Game Price by Release Year", fontsize=14)
plt.xlabel("Release Year")
plt.ylabel("Average Price (USD)")
plt.grid(True, alpha=0.3)

plt.xticks(df["year"], rotation=45)
plt.tight_layout()

plt.show()

